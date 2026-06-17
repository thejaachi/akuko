/// How a catalogue title is delivered to the reader.
enum BookDeliveryFormat {
  ebook,
  audiobook,
  hardcopy;

  static BookDeliveryFormat? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    return switch (value.toLowerCase()) {
      'audiobook' || 'audio' => BookDeliveryFormat.audiobook,
      'hardcopy' || 'hard_copy' || 'physical' => BookDeliveryFormat.hardcopy,
      _ => BookDeliveryFormat.ebook,
    };
  }

  String get wireValue => switch (this) {
        BookDeliveryFormat.ebook => 'ebook',
        BookDeliveryFormat.audiobook => 'audiobook',
        BookDeliveryFormat.hardcopy => 'hardcopy',
      };

  String get label => switch (this) {
        BookDeliveryFormat.ebook => 'Ebook',
        BookDeliveryFormat.audiobook => 'Audiobook',
        BookDeliveryFormat.hardcopy => 'Hardcopy',
      };
}
