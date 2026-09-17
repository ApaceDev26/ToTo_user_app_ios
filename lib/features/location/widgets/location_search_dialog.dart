import 'package:toto_user/features/location/controllers/location_controller.dart';
import 'package:toto_user/features/location/domain/models/prediction_model.dart';
import 'package:toto_user/util/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:toto_user/util/styles.dart';

class LocationSearchDialog extends StatefulWidget {
  final String? pickedLocation;
  final Widget? child;
  final Function(Position)? callBack;
  final bool? fromAddress;

  const LocationSearchDialog({
    super.key,
    this.pickedLocation,
    this.child,
    this.callBack,
    this.fromAddress = false,
  });

  @override
  State<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<LocationSearchDialog> {
  final SearchController controller = SearchController();

  String? _searchingWithQuery;
  late Iterable<Widget> _lastOptions = <Widget>[];
  List<PredictionModel> _predictionList = [];
  List<String> _predictList = <String>[];
  int _searchRequestId = 0;

  @override
  void initState() {
    super.initState();
    controller.text = widget.pickedLocation ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (controller.isAttached && !controller.isOpen) {
      controller.text = widget.pickedLocation ?? '';
    }

    return GetBuilder<LocationController>(
      builder: (locationController) {
        return SearchAnchor(
          searchController: controller,
          viewSurfaceTintColor: Theme.of(context).cardColor,
          isFullScreen: false,
          viewLeading: IconButton(
            onPressed: () => controller.closeView(''),
            icon: const Icon(Icons.arrow_back),
          ),
          viewTrailing: [
            IconButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  controller.text = '';
                } else {
                  controller.closeView('');
                }
              },
              icon: const Icon(Icons.clear),
            ),
          ],
          viewConstraints: const BoxConstraints(
            minHeight: 100,
            maxHeight: 300,
          ),
          builder: (
            BuildContext context,
            SearchController controller,
          ) {
            return widget.child ??
                Container(
                  height: 50,
                  width: 500,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(
                      Dimensions.radiusSmall,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 25,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(
                        width: Dimensions.paddingSizeSmall,
                      ),
                      Expanded(
                        child: Text(
                          controller.text.isNotEmpty
                              ? controller.text
                              : 'search_location'.tr,
                          style: robotoRegular.copyWith(
                            color: controller.text.isEmpty
                                ? Theme.of(context).disabledColor
                                : Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.search),
                    ],
                  ),
                );
          },
          suggestionsBuilder: (
            BuildContext context,
            SearchController controller,
          ) async {
            final String query = controller.text.trim();

            if (query.isEmpty) {
              return [];
            }

            _searchingWithQuery = query;

            final List<String> options =
                (await _search(query, locationController)).toList();

            if (_searchingWithQuery != controller.text.trim()) {
              return _lastOptions;
            }

            _lastOptions = List<ListTile>.generate(
              options.length,
              (int index) {
                final String location = options[index];
                final bool isNoResult =
                    location == 'no_address_found'.tr;

                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(location),
                  enabled: !isNoResult,
                  onTap: isNoResult
                      ? null
                      : () async {
                          if (_predictList.contains(location) &&
                              _predictionList.isNotEmpty) {
                            final int selectedIndex =
                                _predictList.indexOf(location);

                            if (selectedIndex >= 0 &&
                                selectedIndex < _predictionList.length) {
                              final PredictionModel suggestion =
                                  _predictionList[selectedIndex];

                              final Position position =
                                  await Get.find<LocationController>()
                                      .setLocation(
                                suggestion.placeId!,
                                suggestion.description,
                              );

                              if (widget.fromAddress == true &&
                                  widget.callBack != null) {
                                widget.callBack!(position);
                              }

                              controller.closeView(location);
                            }
                          }
                        },
                );
              },
            );

            return _lastOptions;
          },
        );
      },
    );
  }

  Future<Iterable<String>> _search(
    String query,
    LocationController locationController,
  ) async {
    final String trimmedQuery = query.trim();
    final int requestId = ++_searchRequestId;

    if (trimmedQuery.length < 3) {
      return const Iterable<String>.empty();
    }

    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    if (requestId != _searchRequestId) {
      return const Iterable<String>.empty();
    }

    _predictionList =
        await locationController.searchLocation(trimmedQuery);

    if (requestId != _searchRequestId) {
      return const Iterable<String>.empty();
    }

    _predictList = [];

    for (final prediction in _predictionList) {
      if (prediction.description != null &&
          prediction.description!.isNotEmpty) {
        _predictList.add(prediction.description!);
      }
    }

    if (_predictList.isEmpty) {
      _predictList.add('no_address_found'.tr);
    }

    return _predictList;
  }
}
