locals {
  s3_origin_id = "${var.project_name}-s3-origin"

  project_tags = {
    Name        = var.project_name
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }

  # Content-type mapping for S3 object uploads
  content_types = {
    ".html"  = "text/html"
    ".htm"   = "text/html"
    ".css"   = "text/css"
    ".js"    = "application/javascript"
    ".mjs"   = "application/javascript"
    ".json"  = "application/json"
    ".xml"   = "application/xml"
    ".txt"   = "text/plain"
    ".csv"   = "text/csv"
    ".png"   = "image/png"
    ".jpg"   = "image/jpeg"
    ".jpeg"  = "image/jpeg"
    ".gif"   = "image/gif"
    ".svg"   = "image/svg+xml"
    ".webp"  = "image/webp"
    ".ico"   = "image/x-icon"
    ".woff"  = "font/woff"
    ".woff2" = "font/woff2"
    ".ttf"   = "font/ttf"
    ".eot"   = "application/vnd.ms-fontobject"
    ".otf"   = "font/otf"
    ".pdf"   = "application/pdf"
    ".webm"  = "video/webm"
    ".mp4"   = "video/mp4"
    ".mp3"   = "audio/mpeg"
    ".wasm"  = "application/wasm"
    ".map"   = "application/json"
  }
}
