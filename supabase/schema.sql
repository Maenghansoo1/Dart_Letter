-- ══════════════════════════════════════════════════════════════════
--  다트레터 Supabase Schema
--  적용 방법: Supabase Dashboard → SQL Editor → 전체 붙여넣기 → Run
-- ══════════════════════════════════════════════════════════════════


-- ────────────────────────────────────────────────────────────────
-- 1. TABLES
-- ────────────────────────────────────────────────────────────────

-- 기업 기본정보 (DART 기준)
CREATE TABLE IF NOT EXISTS companies (
  corp_code        TEXT        PRIMARY KEY,          -- DART 고유코드 (8자리 숫자)
  name             TEXT        NOT NULL,
  stock_code       TEXT,                             -- 종목코드 (상장사만)
  market           TEXT        CHECK (market IN ('KOSPI', 'KOSDAQ', 'KONEX', NULL)),
  sector           TEXT,
  market_cap       BIGINT,                           -- 시가총액 (원)
  ceo              TEXT,
  established_date DATE,
  listed_date      DATE,
  employee_count   INTEGER,
  updated_at       TIMESTAMPTZ DEFAULT now()
);

-- DART 공시
CREATE TABLE IF NOT EXISTS disclosures (
  rcept_no             TEXT        PRIMARY KEY,      -- 접수번호 (14자리)
  corp_code            TEXT        NOT NULL REFERENCES companies(corp_code),
  title                TEXT        NOT NULL,
  content              TEXT,                         -- 원문 (HTML 제거 후 저장)
  ai_easy_explanation  TEXT,                         -- AI 쉬운 설명 (일반인용)
  ai_summary           TEXT,                         -- AI 3줄 핵심 요약
  disclosure_type      TEXT,                         -- 공시 분류명
  date                 DATE        NOT NULL,
  created_at           TIMESTAMPTZ DEFAULT now()
);

-- 뉴스
CREATE TABLE IF NOT EXISTS news (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  corp_code   TEXT        NOT NULL REFERENCES companies(corp_code),
  title       TEXT        NOT NULL,
  content     TEXT,
  source      TEXT,                                  -- 언론사명
  category    TEXT        NOT NULL
              CHECK (category IN ('공시', '과거이슈', '뉴스')),
  url         TEXT,
  date        DATE        NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- 과거 이슈 (주가 급변 사건)
CREATE TABLE IF NOT EXISTS historical_issues (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  corp_code         TEXT        NOT NULL REFERENCES companies(corp_code),
  date              DATE        NOT NULL,
  title             TEXT        NOT NULL,
  description       TEXT,
  price_change_rate NUMERIC(7, 4),                   -- 등락률(%) 예: -5.2300
  created_at        TIMESTAMPTZ DEFAULT now()
);

-- 주가 (KRX 일별)
CREATE TABLE IF NOT EXISTS stock_prices (
  corp_code   TEXT        NOT NULL REFERENCES companies(corp_code),
  date        DATE        NOT NULL,
  open        INTEGER     NOT NULL,
  high        INTEGER     NOT NULL,
  low         INTEGER     NOT NULL,
  close       INTEGER     NOT NULL,
  volume      BIGINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (corp_code, date)
);

-- 관심종목
CREATE TABLE IF NOT EXISTS watchlist (
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  corp_code   TEXT        NOT NULL REFERENCES companies(corp_code) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, corp_code)
);

-- 커뮤니티 게시글
CREATE TABLE IF NOT EXISTS community_posts (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  corp_code     TEXT        NOT NULL REFERENCES companies(corp_code) ON DELETE CASCADE,
  content       TEXT        NOT NULL CHECK (char_length(content) BETWEEN 1 AND 1000),
  likes         INTEGER     NOT NULL DEFAULT 0,
  comment_count INTEGER     NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT now()
);

-- 커뮤니티 댓글
CREATE TABLE IF NOT EXISTS community_comments (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id     UUID        NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content     TEXT        NOT NULL CHECK (char_length(content) BETWEEN 1 AND 500),
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- 종목 카테고리 태그
CREATE TABLE IF NOT EXISTS categories (
  corp_code       TEXT        NOT NULL REFERENCES companies(corp_code) ON DELETE CASCADE,
  category_name   TEXT        NOT NULL,
  category_type   TEXT        NOT NULL   -- 'market' | 'theme' | 'sector'
                  CHECK (category_type IN ('market', 'theme', 'sector')),
  PRIMARY KEY (corp_code, category_name, category_type)
);

-- 알림
CREATE TABLE IF NOT EXISTS notifications (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type        TEXT        NOT NULL
              CHECK (type IN ('disclosure', 'news', 'comment', 'like')),
  content     TEXT        NOT NULL,
  is_read     BOOLEAN     NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT now()
);


-- ────────────────────────────────────────────────────────────────
-- 2. INDEXES
-- ────────────────────────────────────────────────────────────────

-- disclosures: 기업별 최신순 조회
CREATE INDEX IF NOT EXISTS idx_disclosures_corp_date
  ON disclosures (corp_code, date DESC);

-- disclosures: 날짜 전체 정렬 (홈 피드)
CREATE INDEX IF NOT EXISTS idx_disclosures_date
  ON disclosures (date DESC);

-- news: 기업별 최신순
CREATE INDEX IF NOT EXISTS idx_news_corp_date
  ON news (corp_code, date DESC);

-- news: 카테고리 필터
CREATE INDEX IF NOT EXISTS idx_news_corp_category
  ON news (corp_code, category);

-- historical_issues: 기업별 날짜순
CREATE INDEX IF NOT EXISTS idx_historical_issues_corp_date
  ON historical_issues (corp_code, date DESC);

-- stock_prices: 최신 종가 1건 조회 (PK가 (corp_code, date)이므로 추가 불필요)
-- 단, date DESC 조회 최적화용 별도 인덱스
CREATE INDEX IF NOT EXISTS idx_stock_prices_corp_date
  ON stock_prices (corp_code, date DESC);

-- watchlist: user_id 기준 조회 (PK가 (user_id, corp_code)이므로 커버됨)

-- community_posts: 기업별 최신순
CREATE INDEX IF NOT EXISTS idx_community_posts_corp_date
  ON community_posts (corp_code, created_at DESC);

-- community_posts: 유저별 내 글 조회
CREATE INDEX IF NOT EXISTS idx_community_posts_user
  ON community_posts (user_id);

-- community_comments: 게시글별 댓글 조회
CREATE INDEX IF NOT EXISTS idx_community_comments_post
  ON community_comments (post_id, created_at ASC);

-- community_comments: 유저별 내 댓글 조회
CREATE INDEX IF NOT EXISTS idx_community_comments_user
  ON community_comments (user_id);

-- notifications: 유저별 읽지 않은 알림
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON notifications (user_id, is_read, created_at DESC);


-- ────────────────────────────────────────────────────────────────
-- 3. ROW LEVEL SECURITY
-- ────────────────────────────────────────────────────────────────

-- ── 3-1. 공개 데이터 (SELECT only) ────────────────────────────

ALTER TABLE companies          ENABLE ROW LEVEL SECURITY;
ALTER TABLE disclosures        ENABLE ROW LEVEL SECURITY;
ALTER TABLE news               ENABLE ROW LEVEL SECURITY;
ALTER TABLE historical_issues  ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_prices       ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories         ENABLE ROW LEVEL SECURITY;

CREATE POLICY "companies_select"
  ON companies FOR SELECT USING (true);

CREATE POLICY "disclosures_select"
  ON disclosures FOR SELECT USING (true);

CREATE POLICY "news_select"
  ON news FOR SELECT USING (true);

CREATE POLICY "historical_issues_select"
  ON historical_issues FOR SELECT USING (true);

CREATE POLICY "stock_prices_select"
  ON stock_prices FOR SELECT USING (true);

CREATE POLICY "categories_select"
  ON categories FOR SELECT USING (true);


-- ── 3-2. 관심종목 (본인 전체 권한) ───────────────────────────

ALTER TABLE watchlist ENABLE ROW LEVEL SECURITY;

CREATE POLICY "watchlist_select"
  ON watchlist FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "watchlist_insert"
  ON watchlist FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "watchlist_delete"
  ON watchlist FOR DELETE
  USING (auth.uid() = user_id);


-- ── 3-3. 커뮤니티 게시글 (읽기는 공개, 쓰기는 본인만) ────────

ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "community_posts_select"
  ON community_posts FOR SELECT USING (true);

CREATE POLICY "community_posts_insert"
  ON community_posts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "community_posts_update"
  ON community_posts FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "community_posts_delete"
  ON community_posts FOR DELETE
  USING (auth.uid() = user_id);


-- ── 3-4. 커뮤니티 댓글 (읽기는 공개, 쓰기는 본인만) ─────────

ALTER TABLE community_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "community_comments_select"
  ON community_comments FOR SELECT USING (true);

CREATE POLICY "community_comments_insert"
  ON community_comments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "community_comments_update"
  ON community_comments FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "community_comments_delete"
  ON community_comments FOR DELETE
  USING (auth.uid() = user_id);


-- ── 3-5. 알림 (본인 것만 조회·수정) ──────────────────────────

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notifications_select"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "notifications_update"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);    -- is_read 상태 변경용


-- ────────────────────────────────────────────────────────────────
-- 4. HELPER FUNCTIONS
-- ────────────────────────────────────────────────────────────────

-- 좋아요 atomic 증가 (RLS 우회 없이 안전하게 카운터 처리)
CREATE OR REPLACE FUNCTION increment_post_likes(p_post_id UUID)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  UPDATE community_posts
  SET likes = likes + 1
  WHERE id = p_post_id;
END;
$$;

-- 댓글 추가 시 comment_count 자동 갱신
CREATE OR REPLACE FUNCTION update_comment_count()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE community_posts
    SET comment_count = comment_count + 1
    WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE community_posts
    SET comment_count = GREATEST(comment_count - 1, 0)
    WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$;

CREATE TRIGGER trg_comment_count
  AFTER INSERT OR DELETE ON community_comments
  FOR EACH ROW EXECUTE FUNCTION update_comment_count();
