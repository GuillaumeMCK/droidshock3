import 'package:flutter/widgets.dart';

import 'gap.dart';

/// A ListView widget that constrains its width to a maximum value and centers it
/// within the available space.
///
/// This widget is useful for creating responsive layouts where you want to limit
/// the width of a list on larger screens while keeping it centered.
///
/// Example usage:
/// ```dart
/// ConstrainedListView(
///   maxWidth: 800,
///   spacing: 8.0,
///   children: [
///     ListTile(title: Text('Item 1')),
///     ListTile(title: Text('Item 2')),
///   ],
/// )
///
/// ConstrainedListView.builder(
///   maxWidth: 800,
///   spacing: 12.0,
///   itemCount: items.length,
///   itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
/// )
/// ```
class ConstrainedListView extends StatelessWidget {
  /// Creates a constrained ListView with a list of children.
  const ConstrainedListView({
    super.key,
    required this.children,
    this.maxWidth = 600.0,
    this.maxHeight = .infinity,
    this.spacing = 0.0,
    this.padding = .zero,
    this.scrollController,
    this.alignment = .center,
    this.physics,
  }) : itemCount = null,
       itemBuilder = null;

  /// Creates a constrained ListView with a builder function.
  const ConstrainedListView.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.maxWidth = 600.0,
    this.maxHeight = double.infinity,
    this.spacing = 0.0,
    this.padding = EdgeInsets.zero,
    this.scrollController,
    this.alignment = Alignment.center,
    this.physics,
  }) : children = null;

  /// The number of items in the list (builder constructor only).
  final int? itemCount;

  /// Function that builds list items on demand (builder constructor only).
  final IndexedWidgetBuilder? itemBuilder;

  /// The list of child widgets (standard constructor only).
  final List<Widget>? children;

  /// The maximum width constraint for the ListView.
  ///
  /// The ListView will not exceed this width, even if more space is available.
  final double maxWidth;

  /// The maximum height constraint for the ListView.
  ///
  /// The ListView will not exceed this height, even if more space is available.
  final double maxHeight;

  /// The vertical spacing between list items.
  final double spacing;

  /// The padding around the ListView content.
  final EdgeInsetsGeometry padding;

  /// Optional scroll controller for the ListView.
  final ScrollController? scrollController;

  /// The alignment of the constrained ListView within the available space.
  final Alignment alignment;

  /// The scroll physics to use for the ListView.
  ///
  /// If null, defaults to ClampingScrollPhysics.
  final ScrollPhysics? physics;

  /// Whether this ListView is using the builder pattern.
  bool get _isBuilder => itemBuilder != null && itemCount != null;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: LayoutBuilder(
        builder: (_, constraints) => _buildConstrainedContent(constraints),
      ),
    );
  }

  /// Builds the constrained content based on available space.
  Widget _buildConstrainedContent(BoxConstraints constraints) {
    final effectiveMaxWidth = maxWidth.clamp(0.0, constraints.maxWidth);
    final horizontalPadding = _calculateHorizontalPadding(
      constraints.maxWidth,
      effectiveMaxWidth,
    );
    final effectiveMaxHeight = maxHeight.clamp(0.0, constraints.maxHeight);
    final verticalPadding = _calculateVerticalPadding(
      constraints.maxHeight,
      effectiveMaxHeight,
    );

    return Padding(
      padding: padding,
      child: _buildListView(
        padding: .symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
      ),
    );
  }

  /// Calculates the horizontal padding needed to center the content.
  double _calculateHorizontalPadding(double available, double max) {
    return available > max ? (available - max) / 2 : 0.0;
  }

  /// Calculates the vertical padding needed to center the content.
  double _calculateVerticalPadding(double available, double max) {
    return available > max ? (available - max) / 2 : 0.0;
  }

  /// Builds the appropriate ListView based on the constructor used.
  Widget _buildListView({EdgeInsetsGeometry padding = EdgeInsets.zero}) {
    final effectivePhysics = physics ?? const ClampingScrollPhysics();

    return _isBuilder
        ? ListView.separated(
            physics: effectivePhysics,
            clipBehavior: Clip.none,
            controller: scrollController,
            padding: padding,
            itemCount: itemCount!,
            itemBuilder: itemBuilder!,
            separatorBuilder: (context, index) => Gap(spacing),
          )
        : ListView(
            physics: effectivePhysics,
            clipBehavior: Clip.none,
            controller: scrollController,
            padding: padding,
            children: [
              ...?children?.expand((child) sync* {
                yield child;
                if (child != children!.last) {
                  yield Gap(spacing);
                }
              }),
            ],
          );
  }
}
