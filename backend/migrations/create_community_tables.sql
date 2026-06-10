-- 커뮤니티 게시글 테이블
CREATE TABLE IF NOT EXISTS posts (
  id           uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  corp_code    text        REFERENCES companies(corp_code) ON DELETE SET NULL,
  corp_name    text,
  post_type    text        NOT NULL DEFAULT 'stock' CHECK (post_type IN ('stock', 'info')),
  nickname     text        NOT NULL DEFAULT '익명',
  title        text        NOT NULL,
  content      text        NOT NULL,
  likes_count     integer NOT NULL DEFAULT 0,
  comments_count  integer NOT NULL DEFAULT 0,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS posts_corp_code_idx    ON posts(corp_code);
CREATE INDEX IF NOT EXISTS posts_post_type_idx    ON posts(post_type);
CREATE INDEX IF NOT EXISTS posts_likes_count_idx  ON posts(likes_count DESC);
CREATE INDEX IF NOT EXISTS posts_created_at_idx   ON posts(created_at DESC);

-- 댓글 테이블
CREATE TABLE IF NOT EXISTS comments (
  id         uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id    uuid        NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  nickname   text        NOT NULL DEFAULT '익명',
  content    text        NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS comments_post_id_idx ON comments(post_id);
