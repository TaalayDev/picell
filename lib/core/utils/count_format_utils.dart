/// Compact count for stat labels: 950 -> "950", 1250 -> "1.3K", 2.4M -> "2.4M".
String formatCount(int count) {
  if (count >= 1000000) {
    return '${(count / 1000000).toStringAsFixed(1)}M';
  } else if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(1)}K';
  }
  return count.toString();
}
