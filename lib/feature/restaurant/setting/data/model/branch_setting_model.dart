class BranchModel {
  final String id;
  final String companyId;
  final String restaurantName;
  final String name;         // branch name
  final String city;
  final String address;
  final String phone;
  final String email;
  final String website;
  final String ntn;
  final String strn;
  final String posId;
  final int    tables;
  final bool   isOpen;
  final bool   isActive;
  final bool   is24Hours;
  final String openingTime;
  final String closingTime;
  final String branchType;

  const BranchModel({
    required this.id,
    required this.companyId,
    required this.restaurantName,
    required this.name,
    required this.city,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
    required this.ntn,
    required this.strn,
    required this.posId,
    required this.tables,
    required this.isOpen,
    required this.isActive,
    required this.is24Hours,
    required this.openingTime,
    required this.closingTime,
    required this.branchType,
  });

  factory BranchModel.fromJson(Map<String, dynamic> j) => BranchModel(
    id:             j['id'] as String,
    companyId:      j['company_id'] as String,
    restaurantName: j['restaurant_name'] as String? ?? '',
    name:           j['name'] as String,
    city:           j['city'] as String? ?? '',
    address:        j['address'] as String? ?? '',
    phone:          j['phone'] as String? ?? '',
    email:          j['email'] as String? ?? '',
    website:        j['website'] as String? ?? '',
    ntn:            j['ntn'] as String? ?? '',
    strn:           j['strn'] as String? ?? '',
    posId:          j['pos_id'] as String? ?? '',
    tables:         j['tables'] as int? ?? 0,
    isOpen:         j['is_open'] as bool? ?? false,
    isActive:       j['is_active'] as bool? ?? true,
    is24Hours:      j['is_24_hours'] as bool? ?? false,
    openingTime:    j['opening_time'] as String? ?? '11:00 AM',
    closingTime:    j['closing_time'] as String? ?? '11:30 PM',
    branchType:     j['branch_type'] as String? ?? 'restaurant',
  );

  Map<String, dynamic> toJson() => {
    'restaurant_name': restaurantName,
    'name':            name,
    'city':            city,
    'address':         address,
    'phone':           phone,
    'email':           email,
    'website':         website,
    'ntn':             ntn,
    'strn':            strn,
    'pos_id':          posId,
    'is_24_hours':     is24Hours,
    'opening_time':    openingTime,
    'closing_time':    closingTime,
  };

  BranchModel copyWith({
    String? restaurantName, String? name, String? city, String? address,
    String? phone, String? email, String? website, String? ntn, String? strn,
    String? posId, bool? is24Hours, String? openingTime, String? closingTime,
  }) => BranchModel(
    id:             id,
    companyId:      companyId,
    restaurantName: restaurantName ?? this.restaurantName,
    name:           name           ?? this.name,
    city:           city           ?? this.city,
    address:        address        ?? this.address,
    phone:          phone          ?? this.phone,
    email:          email          ?? this.email,
    website:        website        ?? this.website,
    ntn:            ntn            ?? this.ntn,
    strn:           strn           ?? this.strn,
    posId:          posId          ?? this.posId,
    tables:         tables,
    isOpen:         isOpen,
    isActive:       isActive,
    is24Hours:      is24Hours      ?? this.is24Hours,
    openingTime:    openingTime    ?? this.openingTime,
    closingTime:    closingTime    ?? this.closingTime,
    branchType:     branchType,
  );
}