enum DealVerdict {
  mustBuy('Đáng mua', '🔥'),
  goodPrice('Giá tốt', '👍'),
  consider('Cân nhắc', '🤔'),
  wait('Nên chờ', '⏳');

  const DealVerdict(this.label, this.emoji);

  final String label;
  final String emoji;

  static DealVerdict fromScore(int score) {
    if (score >= 88) return DealVerdict.mustBuy;
    if (score >= 80) return DealVerdict.goodPrice;
    if (score >= 70) return DealVerdict.consider;
    return DealVerdict.wait;
  }
}
