use crate::models::Track;
use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};
use std::path::Path;
use walkdir::WalkDir;
use id3::TagLike;

fn make_id(path: &str) -> String {
    let mut hasher = DefaultHasher::new();
    path.hash(&mut hasher);
    let hash = hasher.finish();
    format!("{:x}", hash)
}

pub fn scan_library(root: &str) -> Vec<Track> {
    let mut tracks = Vec::new();

    for entry in WalkDir::new(root)
    .into_iter()
    .filter_map(|e| e.ok())
    .filter(|e| e.file_type().is_file())
    {
        let path = entry.path();
        if path.extension().and_then(|e| e.to_str()) != Some("mp3") {
            continue;
        }
        let path_str = path.to_string_lossy().to_string();
        let track = extract_metadata(path, &path_str);
        tracks.push(track);
    }
    tracks
}

fn extract_metadata(path: &Path, path_str: &str) -> Track {
    let file_stem = path
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("unknown")
        .to_string();

    let mut title = file_stem.clone();
    let mut artist = "Unknown artist".to_string();
    let mut album = "Unknown album".to_string();

    if let Ok(tag) = id3::Tag::read_from_path(path) {
        if let Some(t) = tag.title() {
            title = t.to_string();
        }
        if let Some(a) = tag.artist() {
            artist = a.to_string();
        }
        if let Some(al) = tag.album() {
            album = al.to_string();
        }
    }

    let duration_secs = mp3_duration::from_path(path)
    .map(|d| d.as_secs())
    .unwrap_or(0);

    Track {
        id: make_id(path_str),
        title,
        artist,
        album,
        duration_secs,
        file_path: path_str.to_string(),
    }

}