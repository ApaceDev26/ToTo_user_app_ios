import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toto_user/api/api_client.dart';
import 'package:toto_user/common/models/product_model.dart';
import 'package:toto_user/common/models/restaurant_model.dart';
import 'package:toto_user/design_system/design_system.dart';
import 'package:toto_user/features/home/widgets/new_item_card_widget.dart';
import 'package:toto_user/helper/responsive_helper.dart';
import 'package:toto_user/util/app_constants.dart';
import 'package:toto_user/util/dimensions.dart';

class AllRestaurantFoodViewWidget extends StatefulWidget {
  const AllRestaurantFoodViewWidget({super.key});

  @override
  State<AllRestaurantFoodViewWidget> createState() =>
      _AllRestaurantFoodViewWidgetState();
}

class _AllRestaurantFoodViewWidgetState
    extends State<AllRestaurantFoodViewWidget> {
  static const int _pageSize = 24;
  final ScrollController _scrollController = ScrollController();
  final Random _random = Random();
  final List<Product> _foods = [];
  final Set<int> _seenIds = {};
  int _nextPage = 1;
  int? _totalPages;
  bool _loading = false;
  bool _finished = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNextPage();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 400 &&
        !_loading &&
        !_finished &&
        !_failed) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_loading || _finished) return;
    setState(() => _loading = true);
    try {
      final api = Get.find<ApiClient>();
      final response = await api.getData(
        '${AppConstants.restaurantUri}/all?offset=$_nextPage&limit=12&filter_data=all',
      );
      if (response.statusCode != 200) {
        throw StateError('Restaurant request failed: ${response.statusCode}');
      }
      final model = RestaurantModel.fromJson(response.body);
      final restaurants = model.restaurants ?? <Restaurant>[];
      restaurants.shuffle(_random);
      final batch = <Product>[];
      // Limit concurrent menu requests while including each restaurant on the page.
      for (var start = 0; start < restaurants.length; start += 4) {
        final group = restaurants.skip(start).take(4);
        final results = await Future.wait(group.map((restaurant) async {
          if (restaurant.id == null) return <Product>[];
          try {
            final menu = await api.getData(
              '${AppConstants.restaurantProductUri}?restaurant_id=${restaurant.id}&category_id=0&offset=1&limit=$_pageSize&type=all',
            );
            if (menu.statusCode != 200) return <Product>[];
            final products =
                ProductModel.fromJson(menu.body).products ?? <Product>[];
            for (final food in products) {
              food.restaurantName ??= restaurant.name;
            }
            return products;
          } catch (_) {
            return <Product>[];
          }
        }));
        for (final products in results) {
          batch.addAll(products);
        }
      }
      batch.shuffle(_random);
      if (!mounted) return;
      setState(() {
        for (final food in batch) {
          if (food.id != null && _seenIds.add(food.id!)) _foods.add(food);
        }
        _totalPages ??= ((model.totalSize ?? restaurants.length) / 12).ceil();
        _nextPage++;
        _finished = restaurants.isEmpty || _nextPage > _totalPages!;
        _failed = false;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_foods.isEmpty && !_loading && !_failed) return const SizedBox();
    final colors = AppColors.of(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault),
            child: Text('all_food_items'.tr,
                style: AppTypography.displayMd(colors.ink).copyWith(
                  fontSize: isDesktop ? 26 : 22,
                )),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          SizedBox(
            height: isDesktop ? 290 : 270,
            child: _foods.isEmpty
                ? Center(
                    child: _failed
                        ? TextButton(
                            onPressed: () => _loadNextPage(),
                            child: Text('retry'.tr),
                          )
                        : const CircularProgressIndicator(),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault),
                    itemCount: _foods.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                    itemBuilder: (context, index) => NewItemCardWidget(
                      product: _foods[index],
                      width: isDesktop ? 190 : 168,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
