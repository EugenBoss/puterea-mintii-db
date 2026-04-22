-- ============================================================
-- KNOWLEDGE BASE STORAGE v1.0
-- Data: 22 Aprilie 2026
-- Scop: Stocare documente + chunk-uri + embeddings pentru PsyMind RAG
-- ============================================================

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;

CREATE TABLE IF NOT EXISTS knowledge_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  filename TEXT NOT NULL UNIQUE,
  doc_type TEXT NOT NULL,
  title TEXT,
  author TEXT,
  year INT,
  verdict TEXT,
  version TEXT,
  axes_relevant TEXT[],
  line_count INT,
  source_date DATE,
  full_text TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS knowledge_chunks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID REFERENCES knowledge_documents(id) ON DELETE CASCADE,
  chunk_index INT NOT NULL,
  content TEXT NOT NULL,
  section_header TEXT,
  token_count INT,
  embedding extensions.vector,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_docs_type
  ON knowledge_documents(doc_type);

CREATE INDEX IF NOT EXISTS idx_docs_filename
  ON knowledge_documents(filename);

CREATE INDEX IF NOT EXISTS idx_chunks_document
  ON knowledge_chunks(document_id);
