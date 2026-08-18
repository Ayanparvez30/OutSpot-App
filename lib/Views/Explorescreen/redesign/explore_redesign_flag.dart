/// Single switch between the old Explore body and the redesign.
///
/// `true`  → search field, seven category pills and the nine carousels
/// `false` → the original Trending card + 2-column category grid
///
/// The stories row, top nav and bottom tab bar are shared and render either
/// way — only the feed beneath them changes.
///
/// Flip this one line to hand the client back the design they already signed
/// off on; nothing else has to be touched, and no old file was rewritten to
/// make the redesign possible.
const bool kUseExploreRedesign = true;
