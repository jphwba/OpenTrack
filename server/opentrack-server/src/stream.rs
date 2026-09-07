use axum::body::Body;
use axum::extract::{Path as AxPath, State};
use axum::http::{header, HeaderMap, HeaderValue, StatusCode};
use axum::response::{IntoResponse, Response};
use std::sync::Arc;
use tokio::fs::File;
use tokio::io::{AsyncReadExt, AsyncSeekExt, SeekFrom};
use tokio_util::io::ReaderStream;

use crate::AppState;

pub async fn stream_track(
    State(state): State<Arc<AppState>>,
    AxPath(id): AxPath<String>,
    headers: HeaderMap,
) -> Response {
    let tracks = state.tracks.lock().await;
    let track = match tracks.iter().find(|t| t.id == id) {
        Some(t) => t.clone(),
        None => return (StatusCode::NOT_FOUND, "Track not found").into_response(),
    };
    drop(tracks);

    let mut file = match File::open(&track.file_path).await {
        Ok(f) => f,
        Err(_) => return (StatusCode::NOT_FOUND, "File missing from disk").into_response(),
    };

    let metadata = match file.metadata().await {
        Ok(m) => m,
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "metadata error").into_response(),
    };
    let file_size = metadata.len();
    let range_header = headers.get(header::RANGE).and_then(|v| v.to_str().ok());

    if let Some(range) = range_header {
        if let Some((start, end)) = parse_range(range, file_size) {
            let chunk_size = end - start + 1;

            if file.seek(SeekFrom::Start(start)).await.is_err() {
                return (StatusCode::INTERNAL_SERVER_ERROR, "Seek failed").into_response();
            }
            let limited = file.take(chunk_size);
            let stream = ReaderStream::new(limited);
            let body = Body::from_stream(stream);

            let mut response = Response::new(body);
            *response.status_mut() = StatusCode::PARTIAL_CONTENT;
            let h = response.headers_mut();
            h.insert(
                header::CONTENT_RANGE,
                HeaderValue::from_str(&format!("bytes {}-{}/{}", start, end, file_size)).unwrap(),
            );
            h.insert(
                header::CONTENT_LENGTH,
                HeaderValue::from_str(&chunk_size.to_string()).unwrap(),
            );
            return response;
        }
    }

    let stream = ReaderStream::new(file);
    let body = Body::from_stream(stream);
    let mut response = Response::new(body);
    let h = response.headers_mut();
    h.insert(header::CONTENT_TYPE, HeaderValue::from_static("audio/mpeg"));
    h.insert(header::ACCEPT_RANGES, HeaderValue::from_static("bytes"));
    h.insert(header::CONTENT_LENGTH, HeaderValue::from_str(&file_size.to_string()).unwrap(),);
    response
}

fn parse_range(range: &str, file_size: u64) -> Option<(u64, u64)> {
    let range = range.strip_prefix("bytes=")?;
    let mut parts = range.splitn(2, '-');
    let start_str = parts.next()?;
    let end_str = parts.next().unwrap_or("");
    let start: u64 = start_str.parse().ok()?;
    let end: u64 = if end_str.is_empty() {
        file_size - 1
    } else {
        end_str.parse().ok()?
    };
    if start > end || end >= file_size {
        return None;
    }
    Some((start, end))
}