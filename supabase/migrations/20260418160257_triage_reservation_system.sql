-- ============================================================
-- TRIAGE RESERVATION SYSTEM v1.0
-- Data: 19 Aprilie 2026
-- Scop: Prevenire coliziuni numerotare in triaje paralele
-- ============================================================

-- 1. TABEL COUNTER-E
CREATE TABLE IF NOT EXISTS triage_counters (
  prefix TEXT PRIMARY KEY,
  last_value INT NOT NULL DEFAULT 0,
  description TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO triage_counters (prefix, last_value, description) VALUES
  ('N',   142, 'Note Draft Framework'),
  ('C',   316, 'Cazuri'),
  ('T',   297, 'Tehnici'),
  ('B',   131, 'Briefuri Training'),
  ('S',   106, 'Surse Registru'),
  ('IND',  55, 'Inductii')
ON CONFLICT (prefix) DO NOTHING;

-- 2. TABEL REZERVARI
CREATE TABLE IF NOT EXISTS triage_reservations (
  id BIGSERIAL PRIMARY KEY,
  assigned_id TEXT NOT NULL UNIQUE,
  prefix TEXT NOT NULL,
  seq_number INT NOT NULL,
  chat_label TEXT,
  source_name TEXT,
  source_year INT,
  item_type TEXT,
  status TEXT NOT NULL DEFAULT 'reserved',
  reserved_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '48 hours',
  committed_at TIMESTAMPTZ,
  committed_doc_id UUID,
  metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_res_status ON triage_reservations(status, expires_at);
CREATE INDEX IF NOT EXISTS idx_res_source ON triage_reservations(source_name, source_year);
CREATE INDEX IF NOT EXISTS idx_res_prefix ON triage_reservations(prefix, seq_number);

-- 3. FUNCTIA ATOMICA DE REZERVARE
CREATE OR REPLACE FUNCTION triage_reserve(
  p_prefix TEXT,
  p_count INT DEFAULT 1,
  p_chat_label TEXT DEFAULT NULL,
  p_source_name TEXT DEFAULT NULL,
  p_source_year INT DEFAULT NULL,
  p_item_type TEXT DEFAULT NULL
)
RETURNS TABLE(assigned_id TEXT, seq_number INT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
DECLARE
  start_val INT;
  i INT;
BEGIN
  UPDATE triage_counters
    SET last_value = last_value + p_count,
        updated_at = NOW()
    WHERE prefix = p_prefix
    RETURNING last_value - p_count + 1 INTO start_val;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Unknown prefix: %. Add to triage_counters first.', p_prefix;
  END IF;

  FOR i IN 0..(p_count - 1) LOOP
    INSERT INTO triage_reservations(
      assigned_id, prefix, seq_number,
      chat_label, source_name, source_year, item_type
    ) VALUES (
      p_prefix || '-' || (start_val + i),
      p_prefix,
      start_val + i,
      p_chat_label, p_source_name, p_source_year, p_item_type
    );

    assigned_id := p_prefix || '-' || (start_val + i);
    seq_number := start_val + i;
    RETURN NEXT;
  END LOOP;
END;
$func$;

-- 4. FUNCTIA DE COMMIT
CREATE OR REPLACE FUNCTION triage_commit(
  p_assigned_ids TEXT[],
  p_doc_id UUID DEFAULT NULL
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
DECLARE affected INT;
BEGIN
  UPDATE triage_reservations
    SET status = 'committed',
        committed_at = NOW(),
        committed_doc_id = p_doc_id
    WHERE assigned_id = ANY(p_assigned_ids)
      AND status = 'reserved';

  GET DIAGNOSTICS affected = ROW_COUNT;
  RETURN affected;
END;
$func$;

-- 5. FUNCTIA DE STATUS
CREATE OR REPLACE FUNCTION triage_status()
RETURNS TABLE(
  prefix TEXT,
  last_value INT,
  active_count BIGINT,
  committed_count BIGINT,
  expired_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
BEGIN
  RETURN QUERY
  SELECT
    c.prefix,
    c.last_value,
    COUNT(r.id) FILTER (WHERE r.status='reserved' AND r.expires_at > NOW()),
    COUNT(r.id) FILTER (WHERE r.status='committed'),
    COUNT(r.id) FILTER (WHERE r.status='reserved' AND r.expires_at <= NOW())
  FROM triage_counters c
  LEFT JOIN triage_reservations r ON r.prefix = c.prefix
  GROUP BY c.prefix, c.last_value
  ORDER BY c.prefix;
END;
$func$;

-- 6. CLEANUP EXPIRATE
CREATE OR REPLACE FUNCTION triage_cleanup_expired()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
DECLARE affected INT;
BEGIN
  UPDATE triage_reservations
    SET status = 'expired'
    WHERE status = 'reserved' AND expires_at < NOW();

  GET DIAGNOSTICS affected = ROW_COUNT;
  RETURN affected;
END;
$func$;

-- 7. PERMISIUNI
GRANT EXECUTE ON FUNCTION triage_reserve         TO service_role;
GRANT EXECUTE ON FUNCTION triage_commit          TO service_role;
GRANT EXECUTE ON FUNCTION triage_status          TO service_role, anon, authenticated;
GRANT EXECUTE ON FUNCTION triage_cleanup_expired TO service_role;
