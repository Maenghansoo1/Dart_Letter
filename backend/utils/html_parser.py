import re
from bs4 import BeautifulSoup


def clean_html(raw: str) -> str:
    """HTML 태그 제거 및 텍스트 정제"""
    soup = BeautifulSoup(raw, "lxml")

    for tag in soup(["script", "style", "head", "meta", "link"]):
        tag.decompose()

    text = soup.get_text(separator="\n")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()
