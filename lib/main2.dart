import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(e, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T extends Object> extends State<Dock<T>> {
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        key: ValueKey(_items.join()),
        mainAxisSize: MainAxisSize.min,
        children: _items
            .map((e) => DockItem(
                  key: ValueKey(e),
                  builder: widget.builder,
                  item: e,
                  replaceItem: replaceItem,
                ))
            .toList(),
      ),
    );
  }

  ///
  void replaceItem({
    required T itemToReplace,
    required T item,
    required Offset startOffset,
    required Offset endOffset,
  }) {
    showOverlayAnimation(
      begin: startOffset,
      end: endOffset,
      context: context,
      child: widget.builder(itemToReplace),
      onEnd: () {
        setState(() {
          int index = _items.indexOf(item);
          _items.remove(itemToReplace);
          _items.insert(index, itemToReplace);
        });
      },
    );
  }
}

/// [Widget] building the [DockItem] contains [item] and [builder].
class DockItem<T extends Object> extends StatefulWidget {
  const DockItem(
      {required this.builder,
      required this.item,
      required this.replaceItem,
      super.key});

  ///
  final T item;

  ///
  final Widget Function(T) builder;

  /// Callback function invoked when an item is dropped.
  final Function({
    required T itemToReplace,
    required T item,
    required Offset startOffset,
    required Offset endOffset,
  }) replaceItem;

  @override
  State<DockItem<T>> createState() => _DockItemState<T>();
}

///
class _DockItemState<T extends Object> extends State<DockItem<T>> {
  ///
  late final Widget _widgetFromBuilder = widget.builder(widget.item);

  ///
  late final T _item = widget.item;

  ///
  Rect _itemBox = Rect.zero;

  ///
  Rect _parentBox = Rect.zero;

  @override
  void initState() {
    super.initState();

    ///
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setItemParameters(context: context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableItem<T>(
      item: _item,
      widgetFromBuilder: _widgetFromBuilder,
      itemBox: _itemBox,
      parentBox: _parentBox,
      replaceItem: widget.replaceItem,
      child: DragTargetItem<T>(
        widgetFromBuilder: _widgetFromBuilder,
        itemBox: _itemBox,
        item: _item,
        replaceItem: widget.replaceItem,
      ),
    );
  }

  ///
  void setItemParameters({required BuildContext context}) {
    setState(() {
      RenderBox itemRenderBox = context.findRenderObject()! as RenderBox;
      RenderBox parent = itemRenderBox.parent! as RenderBox;
      _parentBox = getRectBox(parent);
      _itemBox = getRectBox(itemRenderBox);
    });
  }
}

///
class DraggableItem<T extends Object> extends StatefulWidget {
  const DraggableItem({
    required this.item,
    required this.child,
    required this.itemBox,
    required this.parentBox,
    required this.widgetFromBuilder,
    required this.replaceItem,
    super.key,
  });

  ///
  final T item;

  ///
  final Widget child;

  ///
  final Widget widgetFromBuilder;

  ///
  final Rect itemBox;

  ///
  final Rect parentBox;

  ///
  final Function({
    required T itemToReplace,
    required T item,
    required Offset startOffset,
    required Offset endOffset,
  }) replaceItem;

  @override
  State<DraggableItem<T>> createState() => _DraggableItemState<T>();
}

///
class _DraggableItemState<T extends Object> extends State<DraggableItem<T>> {
  ///
  late Rect parentBox = widget.parentBox;

  ///
  bool isInParentBox = true;

  ///
  bool isDragCancel = false;

  ///
  bool isInAnotherItem = false;

  ///
  double tempHeight = 33;

  ///
  Offset currentPosition = Offset.zero;

  @override
  void didUpdateWidget(covariant DraggableItem<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // if (oldWidget.itemBox != widget.itemBox) {
    //   tempHeight = widget.itemBox.height;
    // }

    // if (oldWidget.isDragEnd != widget.itemBox) {
    isDragCancel = false;
    // }
  }

  @override
  Widget build(BuildContext context) {
    ///отмена и мы не в родителе
    if (isDragCancel && !isInParentBox) {
      return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: widget.itemBox.width),
          // tween: Tween<double>(begin: itemSize.width, end: 0),
          onEnd: () {
            // setTempHeight(230);
          },
          duration: const Duration(milliseconds: 300),
          builder: (context, width, child) {
            return SizedBox(
              height: width,
              width: width,
            );
          });
    }

    ///отмена и мы в родителе
    if (isDragCancel && isInParentBox) {
      return SizedBox(
        height: widget.itemBox.height,
        width: widget.itemBox.width,
      );
    }

    ///мы в родителе и нас тянут или не тянут

    return Draggable<T>(
      data: widget.item,
      feedback:widget.widgetFromBuilder,
      onDragUpdate: onDragUpdate,
      childWhenDragging: getChildWhenDragging(),
      onDragEnd: onDragEnd,
      onDragStarted: onDragStarted,
      onDraggableCanceled: onDraggableCanceled,
      onDragCompleted: onDragCompleted,
      child: widget.child,
    );
  }

  ///
  void onDragUpdate(DragUpdateDetails details) {
    final isContainsParentBox = parentBox.contains(details.localPosition);


    if (isInParentBox != isContainsParentBox) {
      ///setState нужен а то не сужается место
      setState(() {
        isInParentBox = isContainsParentBox;
      });
    }

    ///если в родителе то устанавливаем внутри другого айтема или нет
    if (isInParentBox) {
      final isContainsItemBox = !widget.itemBox.contains(details.localPosition);
      if (isInAnotherItem != isContainsItemBox) {
        setState(() {
          isInAnotherItem = isContainsItemBox;
        });
      }
    }
  }

  ///
  void onDragEnd(DraggableDetails details) {}

  ///
  void onDraggableCanceled(velocity, offset) {
    isDragCancel = true;
    setState(() {});

    widget.replaceItem(
      itemToReplace: widget.item,
      item: widget.item,
      startOffset: offset,
      endOffset: widget.itemBox.topLeft,
    );
    // setTempHeight(widget.itemBox.height);
  }

  ///
  void onDragStarted() {}

  ///
  void onDragCompleted() {
    isInParentBox = true;
    // setTempHeight(widget.itemBox.height);
  }

  ///
  Widget getChildWhenDragging() {
    ///в другом айтоме
    if (isInAnotherItem) {
      return TweenAnimationBuilder(
        tween: Tween<double>(begin: widget.itemBox.width, end: 0),
        onEnd: () {
          tempHeight = 0;
        },
        duration: const Duration(milliseconds: 300),
        builder: (context, width, child) {
          return Container(
            color: Colors.greenAccent,
            width: width,
            height: width,
          );
        },
      );
    }

    ///в родительском айтеме но не в другом айтеме и анимация не отыграла
    if (isInParentBox && !isInAnotherItem && tempHeight != 0) {
      return Container(
        color: Colors.blue,
        width: widget.itemBox.width,
        height: widget.itemBox.width,
      );
    }

    ///в родительском айтеме но не в другом айтеме и анимация  отыграла
    if (isInParentBox && !isInAnotherItem && tempHeight == 0) {
      return TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: widget.itemBox.width),
        // tween: Tween<double>(begin: itemSize.width, end: 0),
        onEnd: () {
          tempHeight = 33;
        },
        duration: const Duration(milliseconds: 300),
        builder: (context, width, child) {
          return Container(
            color: Colors.black87,
            width: width,
            height: width,
          );
        },
      );
    }
    //todo проблемма двойных состояний в точке входа нужно чтобы границы айтема использовались для реакций

    //todo нужно сделать состояние когда я в родителе но зашёл из-за пределов

    //todo наверняка нужно будет передавать состояние вниз чтобы избежать одновременных стостояний и анимаций
    if (isInParentBox && !isInAnotherItem) {}

    ///если за переделами родителя

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: widget.itemBox.width, end: 0),
      // tween: Tween<double>(begin: itemSize.width, end: 0),
      onEnd: () {
        tempHeight = 0;
      },
      duration: const Duration(milliseconds: 300),
      builder: (context, width, child) {
        return Container(
          color: Colors.amberAccent,
          width: width,
          height: width,
        );
      },
    );
  }
}

///
class DragTargetItem<T extends Object> extends StatefulWidget {
  const DragTargetItem({
    required this.widgetFromBuilder,
    required this.replaceItem,
    super.key,
    required this.itemBox,
    required this.item,
  });

  ///
  final T item;

  ///
  final Widget widgetFromBuilder;

  ///
  final Rect itemBox;

  ///
  final Function({
    required T itemToReplace,
    required T item,
    required Offset startOffset,
    required Offset endOffset,
  }) replaceItem;

  @override
  State<DragTargetItem<T>> createState() => _DragTargetItemState<T>();
}

///from dn
class _DragTargetItemState<T extends Object> extends State<DragTargetItem<T>> {
  ///
  bool isOnLeave = false;

  ///
  bool? isFromLeft;

  @override
  Widget build(BuildContext context) {
    return DragTarget<T>(
      builder: builder,
      onWillAcceptWithDetails: onWillAcceptWithDetails,
      onAcceptWithDetails: onAcceptWithDetails,
      onMove: onMove,
      onLeave: onLeave,
    );
  }

  ///
  Widget builder(context, candidateData, rejectedData) {
    /// отображение когда входит нужный айтем
    if (candidateData.isNotEmpty && candidateData.first.runtimeType == T) {
      return getWidgetInDragTarget();
    }

    /// отображение когда выходит нужный айтем
    if (isOnLeave) {
      return getWidgetInDragTargetOnLeave();
    }

    /// стандартное отображение , когда ничего не меняется
    return widget.widgetFromBuilder;
  }

  ///
  bool onWillAcceptWithDetails(DragTargetDetails details) {
    //todo срабатывает когда начинаешь тянуть , нужно избежать первый раз

    isFromLeft = getIsGoFromLeft(
      currentOffset: details.offset,
      itemBoxCenterLeft: widget.itemBox.centerLeft,
    );

    return true;
  }

  ///
  void onAcceptWithDetails(DragTargetDetails details) {
    widget.replaceItem(
      itemToReplace: details.data,
      item: widget.item,
      startOffset: details.offset,
      endOffset: widget.itemBox.topLeft,
    );
  }

  ///
  void onMove(DragTargetDetails details) {}

  ///
  void onLeave(item) {
    isOnLeave = true;
  }

  ///
  Widget getWidgetInDragTarget() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: widget.itemBox.width),
      duration: const Duration(milliseconds: 300),
      builder: (context, width, child) {
        return Container(
            color: Colors.red,
            child: Row(
              children: [
                Padding(
                  // padding: EdgeInsets.only(left: width),
                  padding: EdgeInsets.only(
                    right: isFromLeft! ? width : 0,
                    left: !isFromLeft! ? width : 0,
                  ),
                  child: child,
                ),
              ],
            ));
      },
      child: widget.widgetFromBuilder,
    );
  }

  ///
  Widget getWidgetInDragTargetOnLeave() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: widget.itemBox.width, end: 0),
      duration: const Duration(milliseconds: 300),
      builder: (context, width, child) {
        return Container(
            // color: Colors.blueAccent,
            child: Row(
          children: [
            Padding(
              // padding: EdgeInsets.only(left: width),
              padding: EdgeInsets.only(
                right: isFromLeft! ? width : 0,
                left: !isFromLeft! ? width : 0,
              ),
              child: child,
            ),
          ],
        ));
      },
      child: widget.widgetFromBuilder,
    );

    // return Container(
    //   color: Colors.blueAccent,
    //   child: widgetFromBuilder,
    // );
  }

  ///
  bool getIsGoFromLeft({
    required Offset currentOffset,
    required Offset itemBoxCenterLeft,
  }) {
    //todo нужно узнать если мы идём снузу, то изменить логику смещения
    return (currentOffset.dx - itemBoxCenterLeft.dx).isNegative;
  }
}

///.
Rect getRectBox(RenderBox renderBox) {
  Rect box = renderBox.paintBounds;
  Offset topLeftGlobal = renderBox.localToGlobal(box.topLeft);
  Offset bottomRightGlobal = renderBox.localToGlobal(box.bottomRight);
  return Rect.fromLTRB(topLeftGlobal.dx, topLeftGlobal.dy, bottomRightGlobal.dx,
      bottomRightGlobal.dy);
}

///
void showOverlayAnimation({
  required Offset begin,
  required Offset end,
  required BuildContext context,
  required Function onEnd,
  Widget? child,
}) {
  OverlayEntry? overlayEntry;

  void removeOverlayEntry() {
    overlayEntry?.remove();
    overlayEntry?.dispose();
    overlayEntry = null;

    onEnd();
  }

  overlayEntry = OverlayEntry(
    builder: (BuildContext context) {
      return Stack(
        fit: StackFit.expand,
        children: [
          TweenAnimationBuilder(
            tween: Tween<Offset>(
              begin: begin,
              end: end,
            ),
            duration: const Duration(milliseconds: 1300),
            onEnd: removeOverlayEntry,
            child: child ?? const SizedBox.shrink(),
            builder: (context, offset, child) {
              return Positioned(
                top: offset.dy,
                left: offset.dx,
                child: child!,
              );
            },
          ),
        ],
      );
    },
  );

  Overlay.of(context)
      .insert(overlayEntry!); // Insert overlay entry into the overlay stack
}
