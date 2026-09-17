import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toto_user/features/location/widgets/location_search_dialog.dart';
import 'package:toto_user/util/dimensions.dart';
import 'package:toto_user/util/styles.dart';

class SearchLocationWidget extends StatelessWidget {
  final String? pickedAddress;
  final bool? isEnabled;
  final bool? isPickedUp;
  final bool? fromDialog;
  final String? hint;

  const SearchLocationWidget({
    super.key,
    required this.pickedAddress,
    required this.isEnabled,
    this.isPickedUp,
    this.hint,
    this.fromDialog = false,
  });

  @override
  Widget build(BuildContext context) {
    return LocationSearchDialog(
      child: Container(
        height: fromDialog! ? 40 : 50,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          border: isEnabled != null
              ? Border.all(
                  color: fromDialog!
                      ? Theme.of(context)
                          .disabledColor
                          .withValues(alpha: 0.5)
                      : isEnabled!
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).disabledColor,
                  width: isEnabled!
                      ? fromDialog!
                          ? 1
                          : 2
                      : 1,
                )
              : null,
        ),
        child: Row(
          children: [
            (pickedAddress != null && pickedAddress!.isNotEmpty)
                ? Icon(
                    Icons.location_on,
                    size: 25,
                    color: (isEnabled == null || isEnabled!)
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).disabledColor,
                  )
                : Text(
                    'search_location'.tr,
                    style: robotoRegular.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Expanded(
              child: (pickedAddress != null && pickedAddress!.isNotEmpty)
                  ? Text(
                      pickedAddress!,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text(
                      hint ?? '',
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).hintColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Icon(
              CupertinoIcons.search,
              size: 25,
              color: fromDialog!
                  ? Theme.of(context)
                      .disabledColor
                      .withValues(alpha: 0.5)
                  : Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ],
        ),
      ),
    );
  }
}
