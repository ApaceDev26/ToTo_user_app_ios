import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toto_user/design_system/app_colors.dart';
import 'package:toto_user/common/widgets/custom_button_widget.dart';
import 'package:toto_user/common/widgets/custom_ink_well_widget.dart';
import 'package:toto_user/common/widgets/custom_text_field_widget.dart';
import 'package:toto_user/common/widgets/validate_check.dart';
import 'package:toto_user/features/auth/controllers/auth_controller.dart';
import 'package:toto_user/features/auth/widgets/sign_up_widget.dart';
import 'package:toto_user/features/auth/widgets/social_login_widget.dart';
import 'package:toto_user/features/auth/widgets/trams_conditions_check_box_widget.dart';
import 'package:toto_user/features/splash/controllers/splash_controller.dart';
import 'package:toto_user/features/verification/screens/forget_pass_screen.dart';
import 'package:toto_user/features/verification/screens/forget_pass_screen_phone.dart';
import 'package:toto_user/helper/responsive_helper.dart';
import 'package:toto_user/helper/route_helper.dart';
import 'package:toto_user/util/dimensions.dart';
import 'package:toto_user/util/images.dart';
import 'package:toto_user/util/styles.dart';

class ManualLoginWidget extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final FocusNode phoneFocus;
  final FocusNode passwordFocus;
  final Function() onClickLoginButton;
  final Function()? onWebSubmit;
  final bool socialEnable;
  final Function()? onOtpViewClick;
  const ManualLoginWidget({
    super.key,
    required this.phoneController,
    required this.phoneFocus,
    required this.onClickLoginButton,
    required this.passwordController,
    required this.passwordFocus,
    this.onWebSubmit,
    this.socialEnable = false,
    this.onOtpViewClick,
  });

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    bool isPhone = false;
    bool isEmail = false;
    final config = Get.find<SplashController>().configModel!;
    final bool phoneVerificationEnabled =
        config.centralizeLoginSetup?.phoneVerificationStatus ?? false;
    final bool emailVerificationEnabled =
        config.centralizeLoginSetup?.emailVerificationStatus ?? false;
    final bool otpCapabilityEnabled =
        (config.isSmsActive == true || config.firebaseOtpVerification == true);

    // Show phone option only when admin enabled phone verification AND
    // there is an available OTP capability (SMS or Firebase)
    isPhone = phoneVerificationEnabled && otpCapabilityEnabled;
    // Show email option only when admin enabled email verification
    isEmail = emailVerificationEnabled;
    return GetBuilder<AuthController>(builder: (authController) {
      if (isDesktop) {
        return webView(isDesktop, context, authController);
      }
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 70),
            if (onOtpViewClick != null) ...[
              CustomButtonWidget(
                height: isDesktop ? 50 : null,
                width: isDesktop ? 250 : null,
                buttonText: 'Sign in with OTP'.tr,
                radius: isDesktop ? Dimensions.radiusSmall : 100,
                isBold: false,
                isLoading: authController.isLoading,
                onPressed: onOtpViewClick,
                color: AppColors.of(context).accent,
                textColor: AppColors.of(context).onAccent,
                fontSize: isDesktop
                    ? Dimensions.fontSizeSmall
                    : Dimensions.fontSizeDefault,
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Divider(
                      color: Theme.of(context).disabledColor,
                      thickness: 1,
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Text('Or'.tr,
                      style: robotoRegular.copyWith(
                          color: Theme.of(context).disabledColor)),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    child: Divider(
                      color: Theme.of(context).disabledColor,
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
            ],
            CustomTextFieldWidget(
              onCountryChanged: (countryCode) =>
                  authController.countryDialCode = countryCode.dialCode!,
              countryDialCode: authController.isNumberLogin
                  ? CountryCode.fromCountryCode(
                          Get.find<SplashController>().configModel!.country!)
                      .code
                  : null,
              labelText: 'email_or_phone'.tr,
              hintText: 'enter_email_or_phone'.tr,
              controller: phoneController,
              focusNode: phoneFocus,
              nextFocus: passwordFocus,
              inputType: TextInputType.emailAddress,
              prefixIcon: authController.isNumberLogin ? null : Icons.email,
              onChanged: (String text) {
                final numberRegExp = RegExp(r'^[+]?[0-9]+$');

                if (text.isEmpty && authController.isNumberLogin) {
                  authController.toggleIsNumberLogin();
                }
                if (text.startsWith(numberRegExp) &&
                    !authController.isNumberLogin) {
                  authController.toggleIsNumberLogin();
                  phoneController.text = text.replaceAll("+", "");
                }
                final emailRegExp = RegExp(r'@');
                if (text.contains(emailRegExp) &&
                    authController.isNumberLogin) {
                  authController.toggleIsNumberLogin();
                }
              },
              validator: (String? value) {
                if (authController.isNumberLogin &&
                    ValidateCheck.getValidPhone(
                            authController.countryDialCode + value!) ==
                        "") {
                  return "enter_valid_phone_number".tr;
                }
                // Check if it's a phone number
                if (GetUtils.isPhoneNumber(
                    authController.countryDialCode + value!)) {
                  return null;
                }
                // Check if it's an email
                if (GetUtils.isEmail(value.tr)) {
                  // Additional check: email must end with .com
                  final emailValue = value.trim().toLowerCase();
                  if (!emailValue.endsWith('.com')) {
                    return "enter_valid_email_address".tr;
                  }
                  return null;
                }
                return 'enter_email_address_or_phone_number'.tr;
              },
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),
            CustomTextFieldWidget(
              hintText: 'password'.tr,
              controller: passwordController,
              focusNode: passwordFocus,
              inputAction: TextInputAction.done,
              inputType: TextInputType.visiblePassword,
              prefixIcon: Icons.lock,
              isPassword: true,
              onSubmit: (text) => (GetPlatform.isWeb) ? onWebSubmit : null,
              labelText: 'password'.tr,
              required: false,
              validator: (value) => ValidateCheck.validateEmptyText(
                  value, "please_enter_password".tr),
            ),
            SizedBox(
                height: ResponsiveHelper.isDesktop(context)
                    ? Dimensions.paddingSizeDefault
                    : Dimensions.paddingSizeExtraSmall),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              InkWell(
                onTap: () => authController.toggleRememberMe(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        side: BorderSide(color: Theme.of(context).hintColor),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        activeColor: Theme.of(context).primaryColor,
                        value: authController.isActiveRememberMe,
                        onChanged: (bool? isChecked) =>
                            authController.toggleRememberMe(),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Text('remember_me'.tr, style: robotoRegular),
                  ],
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () {
                  if (FocusScope.of(context).hasFocus) {
                    FocusScope.of(context).unfocus();
                  }
                  if (isPhone && isEmail) {
                    Get.toNamed(RouteHelper.getForgotPassRoute());
                  } else if (isPhone) {
                    Get.toNamed(RouteHelper.getForgotPassRoutePhone());
                  } else if (isEmail) {
                    Get.toNamed(RouteHelper.getForgotPassRoute());
                  }
                },
                child: Text('${'forgot_password'.tr}?',
                    style: robotoRegular.copyWith(
                        color: Theme.of(context).canvasColor)),
              ),
            ]),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            TramsConditionsCheckBoxWidget(authController: authController),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),
            CustomButtonWidget(
              height: isDesktop ? 50 : null,
              width: isDesktop ? 250 : null,
              buttonText: 'login'.tr,
              radius: isDesktop ? Dimensions.radiusSmall : 100,
              isBold: isDesktop ? false : true,
              isLoading: authController.isLoading,
              onPressed: onClickLoginButton,
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('do_not_have_account'.tr,
                    style: robotoRegular.copyWith(
                        color: Theme.of(context).hintColor)),
                InkWell(
                  onTap: authController.isLoading
                      ? null
                      : () {
                          Get.toNamed(RouteHelper.getSignUpRoute());
                        },
                  child: Padding(
                    padding:
                        const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                    child: Text('sign_up'.tr,
                        style: robotoMedium.copyWith(
                            color: Theme.of(context).primaryColor)),
                  ),
                ),
              ],
            ),
            socialEnable
                ? const SocialLoginWidget(onlySocialLogin: false)
                : const SizedBox(),
          ],
        ),
      );
    });
  }

  Widget webView(
      bool isDesktop, BuildContext context, AuthController authController) {
    bool onlyManualLoginEnable = onOtpViewClick == null && !socialEnable;

    // Get verification settings for navigation logic
    final config = Get.find<SplashController>().configModel!;
    final bool phoneVerificationEnabled =
        config.centralizeLoginSetup?.phoneVerificationStatus ?? false;
    final bool emailVerificationEnabled =
        config.centralizeLoginSetup?.emailVerificationStatus ?? false;
    final bool otpCapabilityEnabled =
        (config.isSmsActive == true || config.firebaseOtpVerification == true);

    final bool isPhone = phoneVerificationEnabled && otpCapabilityEnabled;
    final bool isEmail = emailVerificationEnabled;
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
          flex: 5,
          child: Column(children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text('login'.tr,
                  style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeExtraLarge)),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            CustomTextFieldWidget(
              onCountryChanged: (countryCode) =>
                  authController.countryDialCode = countryCode.dialCode!,
              countryDialCode: authController.isNumberLogin
                  ? CountryCode.fromCountryCode(
                          Get.find<SplashController>().configModel!.country!)
                      .code
                  : null,
              labelText: 'email_or_phone'.tr,
              hintText: 'enter_email_or_phone'.tr,
              controller: phoneController,
              focusNode: phoneFocus,
              nextFocus: passwordFocus,
              inputType: TextInputType.emailAddress,
              onChanged: (String text) {
                final numberRegExp = RegExp(r'^[+]?[0-9]+$');

                // Toggle isNumberLogin flag based on input
                if (text.isEmpty && authController.isNumberLogin) {
                  authController.toggleIsNumberLogin();
                } else if (text.startsWith(numberRegExp) &&
                    !authController.isNumberLogin) {
                  authController.toggleIsNumberLogin();
                  // Store the cleaned number temporarily
                  final cleanedText = text.replaceAll("+", "");
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    phoneController.text = cleanedText;
                    phoneController.selection = TextSelection.fromPosition(
                      TextPosition(offset: phoneController.text.length),
                    );
                  });
                } else if (text.contains('@') && authController.isNumberLogin) {
                  authController.toggleIsNumberLogin();
                }
              },
              validator: (String? value) {
                if (authController.isNumberLogin &&
                    ValidateCheck.getValidPhone(
                            authController.countryDialCode + value!) ==
                        "") {
                  return "enter_valid_phone_number".tr;
                }
                // Check if it's a phone number
                if (GetUtils.isPhoneNumber(
                    authController.countryDialCode + value!)) {
                  return null;
                }
                // Check if it's an email
                if (GetUtils.isEmail(value.tr)) {
                  // Additional check: email must end with .com
                  final emailValue = value.trim().toLowerCase();
                  if (!emailValue.endsWith('.com')) {
                    return "enter_valid_email_address".tr;
                  }
                  return null;
                }
                return 'enter_email_address_or_phone_number'.tr;
              },
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),
            CustomTextFieldWidget(
              hintText: '8_character'.tr,
              controller: passwordController,
              focusNode: passwordFocus,
              inputAction: TextInputAction.done,
              inputType: TextInputType.visiblePassword,
              prefixIcon: Icons.lock,
              isPassword: true,
              onSubmit: (text) => (GetPlatform.isWeb) ? onWebSubmit : null,
              labelText: 'password'.tr,
              required: true,
              validator: (value) => ValidateCheck.validateEmptyText(
                  value, "please_enter_password".tr),
            ),
            SizedBox(
                height: ResponsiveHelper.isDesktop(context)
                    ? Dimensions.paddingSizeDefault
                    : Dimensions.paddingSizeExtraSmall),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              InkWell(
                onTap: () => authController.toggleRememberMe(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        side: BorderSide(color: Theme.of(context).hintColor),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        activeColor: Theme.of(context).primaryColor,
                        value: authController.isActiveRememberMe,
                        onChanged: (bool? isChecked) =>
                            authController.toggleRememberMe(),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Text('remember_me'.tr,
                        style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall)),
                  ],
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () {
                  if (FocusScope.of(context).hasFocus) {
                    FocusScope.of(context).unfocus();
                  }
                  Future.delayed(const Duration(milliseconds: 250), () {
                    if (ResponsiveHelper.isDesktop(context)) {
                      // Desktop mode - use dialog replacement
                      if (isPhone && isEmail) {
                        Get.dialog(const ForgetPassScreen(fromDialog: true));
                      } else if (isPhone) {
                        Get.dialog(
                            const ForgetPassScreenPhone(fromDialog: true));
                      } else if (isEmail) {
                        Get.dialog(const ForgetPassScreen(fromDialog: true));
                      }
                    } else {
                      // Mobile mode - use normal navigation
                      if (isPhone && isEmail) {
                        Get.toNamed(RouteHelper.getForgotPassRoute());
                      } else if (isPhone) {
                        Get.toNamed(RouteHelper.getForgotPassRoutePhone());
                      } else if (isEmail) {
                        Get.toNamed(RouteHelper.getForgotPassRoute());
                      }
                    }
                  });
                },
                child: Text('${'forgot_password'.tr}?',
                    style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).disabledColor)),
              ),
            ]),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            TramsConditionsCheckBoxWidget(
                authController: authController, fromDialog: true),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),
            CustomButtonWidget(
              buttonText: 'login'.tr,
              radius: Dimensions.radiusDefault,
              isBold: isDesktop ? false : true,
              isLoading: authController.isLoading,
              onPressed: onClickLoginButton,
              fontSize: Dimensions.fontSizeSmall,
            ),
            onlyManualLoginEnable
                ? Padding(
                    padding:
                        const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('do_not_have_account'.tr,
                              style: robotoRegular.copyWith(
                                  color: Theme.of(context).hintColor)),
                          InkWell(
                            onTap: () {
                              Get.back();
                              Get.dialog(
                                SizedBox(
                                  width: 700,
                                  child: Dialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            Dimensions.radiusSmall)),
                                    backgroundColor:
                                        Theme.of(context).cardColor,
                                    insetPadding: EdgeInsets.zero,
                                    child: SignUpWidget(),
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeExtraSmall),
                              child: Text('sign_up'.tr,
                                  style: robotoMedium.copyWith(
                                      color: Theme.of(context).primaryColor)),
                            ),
                          ),
                        ]),
                  )
                : const SizedBox(),
            const SizedBox(height: Dimensions.paddingSizeLarge),
          ]),
        ),
        !onlyManualLoginEnable
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeExtraOverLarge,
                      vertical: Dimensions.paddingSizeLarge),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 1,
                          child: Container(
                            color: Theme.of(context).disabledColor,
                            width: 100,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'or_login_with'.tr,
                            style: robotoMedium.copyWith(
                                color: Theme.of(context).disabledColor),
                          ),
                        ),
                        SizedBox(
                          height: 1,
                          child: Container(
                            color: Theme.of(context).disabledColor,
                            width: 100,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : const SizedBox(),
        !onlyManualLoginEnable
            ? Expanded(
                flex: 4,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      socialEnable
                          ? const SocialLoginWidget(
                              onlySocialLogin: true, showWelcomeText: false)
                          : const SizedBox(),
                      onOtpViewClick != null
                          ? Container(
                              height: 50,
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(Dimensions.radiusDefault)),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors
                                          .grey[Get.isDarkMode ? 700 : 300]!,
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: const Offset(2, 2))
                                ],
                              ),
                              child: CustomInkWellWidget(
                                onTap: onOtpViewClick!,
                                radius: Dimensions.radiusDefault,
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      Dimensions.paddingSizeSmall),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(Images.otp,
                                            height: 20, width: 20),
                                        const SizedBox(
                                            width: Dimensions.paddingSizeSmall),
                                        Text('otp_sign_in'.tr,
                                            style: robotoMedium.copyWith()),
                                      ]),
                                ),
                              ),
                            )
                          : const SizedBox(),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('do_not_have_account'.tr,
                                style: robotoRegular.copyWith(
                                    color: Theme.of(context).hintColor)),
                            InkWell(
                              onTap: () {
                                Get.back();
                                Get.dialog(
                                  SizedBox(
                                    width: 700,
                                    child: Dialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              Dimensions.radiusLarge)),
                                      backgroundColor:
                                          Theme.of(context).cardColor,
                                      insetPadding: EdgeInsets.zero,
                                      child: SignUpWidget(),
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    Dimensions.paddingSizeExtraSmall),
                                child: Text('sign_up'.tr,
                                    style: robotoMedium.copyWith(
                                        color: Theme.of(context).primaryColor)),
                              ),
                            ),
                          ]),
                    ]))
            : const SizedBox(),
      ]),
    );
  }
}
