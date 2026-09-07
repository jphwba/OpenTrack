mod library;
mod models;
mod stream;

use axum::{
    extract::State,
    routing::get,
    Json, Router,
};
use models::Track;
use std::sync::Arc;
use tower_http::cors::CorsLayer;
use tokio::sync::Mutex;

pub struct AppState {
    pub tracks: Mutex<Vec<Track>>,
}

#[tokio::main]
async fn main() {
    let music_dir = "./music";
    let tracks = library::scan_library(music_dir);
    println!("Indexed {} tracks from {}", tracks.len(), music_dir);

    let state = Arc::new(AppState {
        tracks: Mutex::new(tracks),
    });

    let app = Router::new()
        .route("/api/health", get(health))
        .route("/api/tracks", get(get_tracks))
        .route("/api/stream/{id}", get(stream::stream_track))
        .layer(CorsLayer::permissive())
        .with_state(state);
    let listener = tokio::net::TcpListener::bind("0.0.0.0:5925").await.unwrap();
    println!("Listening on http://localhost:5925");
    axum::serve(listener, app).await.unwrap();
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({ "status": "online" }))
}

async fn get_tracks(
    State(state): State<Arc<AppState>>,
) -> Json<Vec<Track>> {
    let tracks = state.tracks.lock().await;
    Json(tracks.clone())
}