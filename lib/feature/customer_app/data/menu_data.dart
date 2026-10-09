/// Static website content (photos, contact details). The menu itself — categories,
/// dishes and prices — comes live from the POS via [customerMenuProvider].
class MenuData {
  MenuData._();

  static const _img = 'assets/customer';

  /// Home page hero slider, in order.
  static const heroImages = [
    'assets/menu/hero_section.jpg',
    'assets/menu/hero-shawarma.jpg',
  ];
  static const signatureImage = '$_img/shawarma-grill.jpg';
  static const logoImage = '$_img/logo.png';

  /// Photos used by the home page's About collage.
  static const aboutImages = [
    'assets/menu/dam-pookh.jpg',
    'assets/menu/mixed-shawarma-plate.jpg',
    'assets/menu/quarter-pounder.jpg',
  ];

  static const address = '91 Walton Road, Woking, Surrey, GU21 5DW';
  static const phone = '01483 838378';
  static const email = 'info@pakafghanrestaurant.co.uk';
}

/// Which POS branch's menu the website shows and where its orders go.
/// Change this to another row of the `branches` table to point the site elsewhere.
const kWebsiteBranchId = 'f9222fe0-3356-4473-883f-d38f192d0efb'; // Pizza Hub 2
