import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/Utils/colors.dart'; // adjust path if needed

class CustomTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool isRequired;
  final String? initialValue;
  final Widget suffixIcon;

  const CustomTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.isRequired = true,
    this.initialValue,  required this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return "This field is required";
        }
        return null;
      },
      style: GoogleFonts.notoSans(
        fontSize: 15.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.white,
      ),
      decoration: InputDecoration(suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.only(left: 25.w, top: 12.h, bottom: 12.h),
        hintText: hint,
        hintStyle: GoogleFonts.notoSans(
          fontSize: 15.sp,
          fontWeight: FontWeight.w400,
          color: AppColors.fillnoti,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13.r),
          borderSide: BorderSide(color: AppColors.fillnoti, width: 1.5.w),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13.r),
          borderSide: BorderSide(color: AppColors.fillnoti, width: 1.5.w),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13.r),
          borderSide: BorderSide(color: AppColors.fillnoti, width: 1.5.w),
        ),
        filled: true,
        fillColor: Colors.transparent,
      ),
    );
  }
}

//  Widget _buildTopPreview() {
//     return Obx(() {
//       final controller = Get.find<CreateprofileController>();
//       final selected = controller.selectedCategory.value;

//       return SizedBox(
//         height: 180.h,
//         child: SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           padding: EdgeInsets.symmetric(horizontal: 15.w),
//           child: Row(
//             children:
//                 OutfitCategory.values.map((cat) {
//                   String itemImage = '';
//                   String label = '';
//                   switch (cat) {
//                     case OutfitCategory.top:
//                       itemImage = controller.selectedTop.value;
//                       label = "Top";
//                       break;
//                     case OutfitCategory.bottom:
//                       itemImage = controller.selectedBottom.value;
//                       label = "Bottom";
//                       break;
//                     case OutfitCategory.shoes:
//                       itemImage = controller.selectedShoe.value;
//                       label = "Shoes";
//                       break;
//                     case OutfitCategory.glasses:
//                       itemImage = controller.selectedGlasses.value;
//                       label = "Glasses";
//                       break;
//                     case OutfitCategory.makeup:
//                       itemImage = controller.selectedMakeup.value;
//                       label = "Accessory";
//                       break;
//                     case OutfitCategory.purse:
//                       itemImage = controller.selectedPurse.value;
//                       label = "Accessory";
//                       break;
//                     case OutfitCategory.ornament:
//                       itemImage = controller.selectedOrnament.value;
//                       label = "Accessory";
//                       break;
//                   }

//                   bool isActive = cat == selected;

//                   return Padding(
//                     padding: EdgeInsets.only(right: 10.w),
//                     child: Stack(
//                       children: [
//                         AnimatedContainer(
//                           duration: Duration(milliseconds: 250),
//                           width: isActive ? 130.w : 100.w,
//                           height: isActive ? 130.h : 100.h,
//                           decoration: BoxDecoration(
//                             border: Border.all(
//                               color:
//                                   isActive
//                                       ? Color(0xff66CCFC)
//                                       : Color(0xffE8EAEB),
//                               width: 2.w,
//                             ),
//                             borderRadius: BorderRadius.circular(12.r),
//                           ),
//                           child:
//                               itemImage.isNotEmpty
//                                   ? ClipRRect(
//                                     borderRadius: BorderRadius.circular(12.r),
//                                     child: Image.asset(
//                                       itemImage,
//                                       fit: BoxFit.cover,
//                                     ),
//                                   )
//                                   : const SizedBox.shrink(),
//                         ),
//                         if (label.isNotEmpty)
//                           Positioned(
//                             bottom: 5.h,
//                             left: 10.w,
//                             child: Center(
//                               child: Container(
//                                 padding: EdgeInsets.symmetric(
//                                   horizontal: 8.w,
//                                   vertical: 3.h,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: const Color(0xff66CCFC),
//                                   borderRadius: BorderRadius.circular(20.r),
//                                 ),
//                                 child: Text(
//                                   label,
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 13.sp,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   );
//                 }).toList(),
//           ),
//         ),
//       );
//     });
//   }

//   Widget _buildCategorySelector() {
//     final controller = Get.find<CreateprofileController>();
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 10.w),
//       child: Obx(() {
//         final selected = controller.selectedCategory.value;

//         // Map category to image paths
//         final Map<OutfitCategory, String> categoryIcons = {
//           OutfitCategory.top: 'assets/Images/ss.png',
//           OutfitCategory.bottom: 'assets/Images/selectesPants.png',
//           OutfitCategory.shoes: 'assets/Images/ssss.png',
//           OutfitCategory.glasses: 'assets/Images/sss.png',
//           OutfitCategory.makeup: 'assets/Images/lipsticIcon.png',
//           OutfitCategory.purse: 'assets/Images/bagIcon.png',
//           OutfitCategory.ornament: 'assets/Images/ssss.png',
//         };

//         return SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.start,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children:
//                 OutfitCategory.values.map((cat) {
//                   final isSelected = cat == selected;

//                   return GestureDetector(
//                     onTap: () => controller.selectedCategory.value = cat,
//                     child: Container(
//                       height: 40.h,
//                       width: 45.w,
//                       margin: EdgeInsets.symmetric(horizontal: 8.w),
//                       // padding: EdgeInsets.all(10.sp),
//                       decoration: BoxDecoration(
//                         color:
//                             isSelected
//                                 ? const Color(0xff66CCFC)
//                                 : Color(0xffEAEAEA),
//                         borderRadius: BorderRadius.circular(7.sp),
//                       ),
//                       child: Image.asset(
//                         categoryIcons[cat]!,
//                         // height: 30.h,
//                         // width: 30.w,
//                         // color:
//                         //     isSelected
//                         //         ? const Color(0xff66CCFC)
//                         //         : Colors.transparent,
//                       ),
//                     ),
//                   );
//                 }).toList(),
//           ),
//         );
//       }),
//     );
//   }

//   Widget _buildItemGrid() {
//     final controller = Get.find<CreateprofileController>();
//     return Obx(() {
//       final category = controller.selectedCategory.value;
//       final items = controller.outfitItems[category] ?? [];
//       String selectedItem = '';
//       switch (category) {
//         case OutfitCategory.top:
//           selectedItem = controller.selectedTop.value;
//           break;
//         case OutfitCategory.bottom:
//           selectedItem = controller.selectedBottom.value;
//           break;
//         case OutfitCategory.shoes:
//           selectedItem = controller.selectedShoe.value;
//           break;
//         case OutfitCategory.glasses:
//           selectedItem = controller.selectedGlasses.value;
//           break;
//         case OutfitCategory.makeup:
//           selectedItem = controller.selectedMakeup.value;
//           break;
//         case OutfitCategory.purse:
//           selectedItem = controller.selectedPurse.value;
//           break;
//         case OutfitCategory.ornament:
//           selectedItem = controller.selectedOrnament.value;
//           break;
//         default:
//           selectedItem = '';
//       }

//       return Expanded(
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
//           child: GridView.builder(
//             itemCount: items.length,
//             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               mainAxisSpacing: 10.h,
//               crossAxisSpacing: 10.w,
//             ),
//             itemBuilder: (context, index) {
//               final imagePath = items[index];
//               final isSelected = imagePath == selectedItem;
//               return GestureDetector(
//                 onTap: () => controller.selectItem(imagePath),
//                 child: Stack(
//                   children: [
//                     Container(
//                       padding: EdgeInsets.all(4.w),
//                       decoration: BoxDecoration(
//                         border: Border.all(
//                           color:
//                               isSelected
//                                   ? Color(0xff42D880)
//                                   : Colors.transparent,
//                           width: 2,
//                         ),
//                         borderRadius: BorderRadius.circular(10.r),
//                       ),
//                       child: Image.asset(imagePath),
//                     ),
//                     if (isSelected)
//                       Positioned(
//                         top: 7.h,
//                         left: 7.w,
//                         child: Image.asset("assets/Images/imageSelection.png"),
//                       ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//       );
//     });
//   }

// const String _mapStyleUrbanPastel = '''
// [
//   {"featureType":"all","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
//   {"featureType":"all","elementType":"labels.text.fill","stylers":[{"color":"#5B6B7A"}]},
//   {"featureType":"all","elementType":"labels.text.stroke","stylers":[{"color":"#FFFFFF"},{"weight":2}]},

//   {"featureType":"water","elementType":"geometry","stylers":[{"color":"#DFF7FF"}]},
//   {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#E9FFFD"}]},
//   {"featureType":"landscape.man_made","elementType":"geometry.fill","stylers":[{"color":"#DDF7F4"}]},
//   {"featureType":"poi","elementType":"geometry.fill","stylers":[{"color":"#EAF3FF"}]},
//   {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#EAF9EE"}]},
//   {"featureType":"poi.business","elementType":"geometry.fill","stylers":[{"color":"#EEF5FF"}]},

//   {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#99A9B9"}]},
//   {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#7E8A96"}]},
//   {"featureType":"road.highway","elementType":"geometry.fill","stylers":[{"color":"#7B8894"}]},
//   {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#6D7985"}]},
//   {"featureType":"road.arterial","elementType":"geometry.fill","stylers":[{"color":"#A8B4C2"}]},
//   {"featureType":"road.local","elementType":"geometry.fill","stylers":[{"color":"#B9C7D3"}]},

//   {"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#D9E6F3"}]},
//   {"featureType":"transit.station","elementType":"geometry.fill","stylers":[{"color":"#F1F6FF"}]}
// ]
// ''';

                    // onMapCreated: (c) {
                    //   controller.onMapCreated(c);
                    //   c.setMapStyle(controller.mapStyleUrbanPastel);
                    // },
                    // onMapCreated: (GoogleMapController controller) {
                    //   controller.setMapStyle(_mapStyle);
                    // },

  // final String _mapStyle = '''
  // [
  //   {
  //     "elementType": "geometry",
  //     "stylers": [
  //       {
  //         "color": "#E9FFFD"
  //       }
  //     ]
  //   },
  //   {
  //     "featureType": "road",
  //     "elementType": "geometry",
  //     "stylers": [
  //       {
  //         "color": "#99A9B9" 
  //       }
  //     ]
  //   },
  //   {
  //     "featureType": "road.local",
  //     "elementType": "geometry",
  //     "stylers": [
  //       {
  //         "color": "#99A9B9"
  //       }
  //     ]
  //   }
  // ]
  // ''';  
    // void _updateMarker(Position pos) {
  //   userMarker.value = {
  //     Marker(
  //       markerId: const MarkerId('me'),
  //       position: LatLng(pos.latitude, pos.longitude),
  //       infoWindow: const InfoWindow(title: 'You are here'),
  //       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
  //     ),
  //   };
  // }               


            // onTap: () {
          //   showDialog(
          //     context: Get.context!,
          //     builder: (context) {
          //       return AlertDialog(
          //         insetPadding: EdgeInsets.symmetric(horizontal: 15.w),
          //         backgroundColor: Color(0xffFFFFFF),
          //         title: Center(
          //           child: Text(
          //             'Story by $username',
          //             style: GoogleFonts.notoSans(
          //               fontSize: 20.sp,
          //               fontWeight: FontWeight.bold,
          //               color: Colors.blue,
          //             ),
          //           ),
          //         ),
          //         content: Column(
          //           mainAxisSize: MainAxisSize.min,
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Image.network(imageUrl),
          //             SizedBox(height: 10),
          //             Center(
          //               child: Text(
          //                 locationName,
          //                 style: GoogleFonts.notoSans(
          //                   fontSize: 20.sp,
          //                   fontWeight: FontWeight.bold,
          //                   color: Colors.blue,
          //                 ),
          //               ),
          //             ),
          //           ],
          //         ),
          //         actions: [
          //           TextButton(
          //             onPressed: () {
          //               Get.back(); // Close dialog
          //             },
          //             child: Text(
          //               "Close",
          //               style: GoogleFonts.notoSans(
          //                 fontSize: 16.sp,
          //                 fontWeight: FontWeight.w500,
          //                 color: Colors.black,
          //               ),
          //             ),
          //           ),
          //         ],
          //       );
          //     },
          //   );
          // },