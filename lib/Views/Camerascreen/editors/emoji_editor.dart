import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_state.dart';

class EmojiEditorPanel extends StatelessWidget {
  final Function(EmojiLayer) onAdd;
  final VoidCallback onClose;

  const EmojiEditorPanel({
    super.key,
    required this.onAdd,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: onClose,
                  child: Text(
                    'Close',
                    style: GoogleFonts.notoSans(
                      color: Colors.white70,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                Text(
                  'Emoji',
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            SizedBox(height: 12.h),

            // Emoji grid
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 8.h,
                  crossAxisSpacing: 8.w,
                ),
                itemCount: _emojis.length,
                itemBuilder: (_, i) {
                  return GestureDetector(
                    onTap: () {
                      // Offset each emoji so they don't stack on top of each other
                      final screenWidth = MediaQuery.of(context).size.width;
                      final screenHeight = MediaQuery.of(context).size.height;
                      final centerX = (screenWidth / 2) - 20 + (DateTime.now().millisecond % 40 - 20);
                      final centerY = (screenHeight / 3) + (DateTime.now().millisecond % 40 - 20);
                      onAdd(
                        EmojiLayer(
                          position: Offset(centerX, centerY),
                          emoji: _emojis[i],
                          scale: 1.0,
                        ),
                      );
                    },
                    child: Center(
                      child: Text(
                        _emojis[i],
                        style: TextStyle(fontSize: 28.sp),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<String> _emojis = [
    // --- Smileys & Emotions ---
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '🥲', '🥹',
    '☺️', '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘',
    '😗', '😙', '😚', '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐',
    '🤓', '😎', '🥸', '🤩', '🥳', '😏', '😒', '😞', '😔', '😟',
    '😕', '🙁', '☹️', '😣', '😖', '😫', '😩', '🥺', '😢', '😭',
    '😮‍💨', '😤', '😠', '😡', '🤬', '🤯', '😳', '🥵', '🥶', '😱',
    '😨', '😰', '😥', '😓', '🫣', '🤗', '🫡', '🤔', '🤫', '🫢',
    '🤭', '🥱', '😴', '🤤', '😪', '😵', '😵‍💫', '🤐', '🥴', '🤢',
    '🤮', '🤧', '😷', '🤒', '🤕', '🤑', '🤠', '😈', '👿', '👹',
    '👺', '🤡', '💩', '👻', '💀', '☠️', '👽', '👾', '🤖',

    // --- People & Body (Gestures) ---
    '👋', '🤚', '🖐️', '✋', '🖖', '👌', '🤌', '🤏', '✌️', '🤞',
    '🫰', '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕', '👇', '☝️',
    '👍', '👎', '✊', '👊', '🤛', '🤜', '👏', '🙌', '🫶', '👐',
    '🤲', '🤝', '🙏', '✍️', '💅', '🤳', '💪', '🧠', '👀', '👁️',

    // --- Animals & Nature ---
    '🐵', '🐒', '🦍', '🐶', '🐕', '🐩', '🐺', '🦊', '🦝', '🐱',
    '🐈', '🦁', '🐯', '🐅', '🐆', '🐴', '🐎', '🦄', '🦓', '🦌',
    '🐮', '🐂', '🐄', '🐷', '🐖', '🐗', '🐽', '🐏', '🐑', '🐐',
    '🐪', '🐫', '🦙', '🦒', '🐘', '🦏', '🦛', '🐭', '🐁', '🐀',
    '🐹', '🐰', '🐇', '🐿️', '🦔', '🦇', '🐻', '🐨', '🐼', '🦥',
    '🦦', '🦨', '🦘', '🦡', '🐾', '🦃', '🐔', '🐓', '🐣', '🐤',
    '🐥', '🐦', '🐧', '🕊️', '🦅', '🦆', '🦢', '🦉', '🦩', '🦚',
    '🦜', '🐸', '🐊', '🐢', '🦎', '🐍', '🐲', '🐉', '🦕', '🦖',
    '🐳', '🐋', '🐬', '🦭', '🐟', '🐠', '🐡', '🦈', '🐙', '🐚',
    '🐌', '🦋', '🐛', '🐜', '🐝', '🪲', '🐞', '🦗', '🕷️', '🕸️',
    '🦂', '🦟', '🦠', '💐', '🌸', '💮', '🪷', '🏵️', '🌹', '🥀',
    '🌺', '🌻', '🌼', '🌷', '🌱', '🪴', '🌲', '🌳', '🌴', '🌵',
    '🌾', '🌿', '☘️', '🍀', '🍁', '🍂', '🍃',

    // --- Food & Drink ---
    '🍇', '🍈', '🍉', '🍊', '🍋', '🍌', '🍍', '🥭', '🍎', '🍏',
    '🍐', '🍑', '🍒', '🍓', '🫐', '🥝', '🍅', '🫒', '🥥', '🥑',
    '🍆', '🥔', '🥕', '🌽', '🌶️', '🫑', '🥒', '🥬', '🥦', '🧄',
    '🧅', '🍄', '🥜', '🌰', '🍞', '🥐', '🥖', '🥨', '🥯', '🥞',
    '🧇', '🧀', '🍖', '🍗', '🥩', '🥓', '🍔', '🍟', '🍕', '🌭',
    '🥪', '🌮', '🌯', '🥙', '🧆', '🥚', '🍳', '🥘', '🍲', '🥣',
    '🥗', '🍿', '🧈', '🧂', '🥫', '🍱', '🍘', '🍙', '🍚', '🍛',
    '🍜', '🍝', '🍠', '🍢', '🍣', '🍤', '🍥', '🥮', '🍡', '🥟',
    '🥠', '🥡', '🦀', '🦞', '🦐', '🦑', '🦪', '🍦', '🍧', '🍨',
    '🍩', '🍪', '🎂', '🍰', '🧁', '🥧', '🍫', '🍬', '🍭', '🍮',
    '🍯', '🍼', '🥛', '☕', '🫖', '🍵', '🍶', '🍾', '🍷', '🍸',
    '🍹', '🍺', '🍻', '🥂', '🥃', '🥤', '🧋', '🧃', '🧉', '🧊',

    // --- Activities, Travel & Transport ---
    '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱',
    '🪀', '🏓', '🏸', '🏒', '🏑', '🥍', '🏏', '🪃', '🥅', '⛳',
    '🪁', '🏹', '🎣', '🤿', '🥊', '🥋', '🎽', '🛹', '🛼', '🛷',
    '⛸️', '🎯', '🎮', '🕹️', '🎰', '🎲', '🧩', '🧸', '🪅', '🪩',
    '🚗', '🚕', '🚙', '🚌', '🚎', '🏎️', '🚓', '🚑', '🚒', '🚐',
    '🛻', '🚚', '🚛', '🚜', '🦯', '🦽', '🦼', '🛴', '🚲', '🛵',
    '🏍️', '🛺', '🚨', '🚔', '🚍', '🚘', '🚖', '🚡', '🚠', '🚟',
    '🚃', '🚋', '🚞', '🚝', '🚄', '🚅', '🚈', '🚂', '🚆', '🚇',
    '🚊', '🚉', '✈️', '🛫', '🛬', '🛩️', '🚀', '🛸', '🚁', '🛶',
    '⛵', '🚤', '🛥️', '🛳️', '⛴️', '🚢', '⚓', '🪝', '⛽', '🚧',

    // --- Objects ---
    '📱', '📲', '💻', '⌨️', '🖥️', '🖨️', '🖱️', '🖲️', '🕹️', '🗜️',
    '💽', '💾', '💿', '📀', '📼', '📷', '📸', '📹', '🎥', '📽️',
    '🎞️', '📞', '☎️', '📟', '📠', '📺', '📻', '🎙️', '🎚️', '🎛️',
    '🧭', '⏱️', '⏲️', '⏰', '🕰️', '⌛', '⏳', '📡', '🔋', '🔌',
    '💡', '🔦', '🕯️', '🪔', '🧯', '🛢️', '💸', '💵', '💴', '💶',
    '💷', '🪙', '💰', '💳', '💎', '⚖️', '🪜', '🧰', '🪛', '🔧',
    '🔨', '⚒️', '🛠️', '⛏️', '🪚', '🔩', '⚙️', '🪤', '🧱', '⛓️',
    '🧲', '🔫', '🧨', '💣', '🔪', '🗡️', '⚔️', '🛡️', '🚬', '⚰️',
    '🪦', '⚱️', '🏺', '🔮', '📿', '🧿', '💈', '⚗️', '🔭', '🔬',
    '🕳️', '🩹', '🩺', '💊', '💉', '🩸', '🧬', '🦠', '🧫', '📚',

    // --- Symbols & Hearts ---
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🤎', '🖤', '🤍', '💔',
    '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💯', '💢',
    '💥', '💫', '💦', '💨', '💬', '👁️‍🗨️', '🗨️', '🗯️', '💭', '💤',
    '⭐', '🌟', '✨', '⚡', '🔥', '🌈', '☀️', '🌙', '♈', '♉',
    '♊', '♋', '♌', '♍', '♎', '♏', '♐', '♑', '♒', '♓',
    '⛎', '▶️', '⏩', '⏭️', '⏯️', '◀️', '⏪', '⏮️', '🔼', '⏫',
    '🔽', '⏬', '⏸️', '⏹️', '⏺️', '⏏️', '🎦', '🔅', '🔆', '📶',
    '✖️', '➕', '➖', '➗', '🟰', '♾️', '‼️', '⁉️', '❓', '❔',
    '❕', '❗', '〰️', '💱', '💲', '⚕️', '♻️', '⚜️', '🔱', '📛',
    '🔰', '⭕', '✅', '☑️', '✔️', '❌', '❎', '➰', '➿', '〽️',
    '#️⃣', '*️⃣', '0️⃣', '1️⃣', '2️⃣', '3️⃣', '4️⃣', '5️⃣', '6️⃣', '7️⃣',
    '8️⃣', '9️⃣', '🔟',

    // --- Flags ---
    '🏁', '🚩', '🎌', '🏴', '🏳️', '🏳️‍🌈', '🏳️‍⚧️', '🏴‍☠️',
    '🇧🇩', // Bangladesh
    '🇮🇳', // India
    '🇵🇰', // Pakistan
    '🇺🇸', // United States
    '🇬🇧', // United Kingdom
    '🇨🇦', // Canada
    '🇦🇺', // Australia
    '🇸🇦', // Saudi Arabia
    '🇦🇪', // United Arab Emirates
    '🇲🇾', // Malaysia
    '🇸🇬', // Singapore
    '🇯🇵', // Japan
    '🇰🇷', // South Korea
    '🇨🇳', // China
    '🇷🇺', // Russia
    '🇩🇪', // Germany
    '🇫🇷', // France
    '🇮🇹', // Italy
    '🇪🇸', // Spain
    '🇧🇷', // Brazil
    '🇦🇷', // Argentina
    '🇿🇦', // South Africa
    '🇳🇬', // Nigeria
    '🇪🇬', // Egypt
    '🇹🇷', // Turkey
    '🇮🇩', // Indonesia
    '🇵🇭', // Philippines
    '🇻🇳', // Vietnam
    '🇹🇭', // Thailand
    '🇳🇵', // Nepal
    '🇱🇰', // Sri Lanka
    '🇲🇻', // Maldives
    '🇦🇫', // Afghanistan
    '🇧🇹', // Bhutan
    '🇶🇦', // Qatar
    '🇰🇼', // Kuwait
    '🇴🇲', // Oman
    '🇲🇽', // Mexico
  ];
}
