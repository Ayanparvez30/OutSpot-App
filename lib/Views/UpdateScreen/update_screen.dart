import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outspot/CommonWidgets/CustomWidgets/customWidget.dart';
import 'package:outspot/Utils/colors.dart';
import 'package:outspot/Views/UpdateScreen/update_screen_controller.dart';
import 'package:outspot/utils/routes.dart';

class UpdateScreen extends GetView<UpdateScreenController> {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          stops: [0.0, 0.6],
        ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            color: Colors.white,
            onPressed: () {
              Get.back();
            },
            icon: SvgPicture.asset(
              "assets/svg/icons/back_icon.svg",
              width: 25.r,
              height: 25.r,
            ),

            padding: EdgeInsets.all(8.w),
            constraints: const BoxConstraints(),
          ),

          title: Text(
            'Update My Name',

            style: GoogleFonts.notoSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomWidgets().customTextField(
                    hint: "First Name",
                    controller: controller.firstNameController,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'First name is required';
                      if (value.length < 3)
                        return 'First name must be at least 3 characters';
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  CustomWidgets().customTextField(
                    hint: "Last Name",
                    controller: controller.lastNameController,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Last name is required';
                      if (value.length < 3)
                        return 'Last name must be at least 3 characters';
                      return null;
                    },
                  ),

                  const Spacer(),

                  // Save Button
                  Obx(() {
                    final enabled = controller.hasChanged.value;
                    return Opacity(
                      opacity: enabled ? 1.0 : 0.5,
                      child: IgnorePointer(
                        ignoring: !enabled,
                        child: CustomWidgets().CustomButton(
                          text: "Save",
                          onPressed: () {
                            if (controller.formKey.currentState!.validate()) {
                              final firstName = controller
                                  .firstNameController.text
                                  .trim();
                              final lastName =
                                  controller.lastNameController.text.trim();
                              controller.updateName(
                                firstName: firstName,
                                lastName: lastName,
                              );
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
