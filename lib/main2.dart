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
    );

    setState(() {
      int index = _items.indexOf(item);
      _items.remove(itemToReplace);
      _items.insert(index, itemToReplace);
    });
  }

  ///
  void showOverlayAnimation({
    required Offset begin,
    required Offset end,
    required BuildContext context,
    Widget? child,
  }) {
    OverlayEntry? overlayEntry;

    void removeOverlayEntry() {
      //todo не всегда удаляется если анимация не отыграла до конца а уже что-то поменялось
      overlayEntry?.remove();
      overlayEntry?.dispose();
      overlayEntry = null;
    }

    overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: end.dy,
              left: end.dx,
              child: Container(
                height: 64,
                width: 64,
                color: const Color(0xffDFD9DF),
              ),
            ),
            TweenAnimationBuilder(
              tween: Tween<Offset>(
                begin: begin,
                end: end,
              ),
              duration: const Duration(milliseconds: 300),
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
  late Widget widgetFromBuilder = widget.builder(widget.item);

  ///
  late T item = widget.item;

  ///
  late Rect parentBox;

  ///
  late bool isInParentBox;

  ///
  late Size itemSize;

  ///
  late Rect itemBox;

  ///
  late double tempHeight;

  ///
  late bool isDragging;

  ///
  late bool isInAnotherItem;

  @override
  void initState() {
    super.initState();
    print('$item initState');
    setDefaultValues();

    ///
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setItemParameters(context: context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('${item} didChangeDependencies');
  }


  @override
  void didUpdateWidget(covariant DockItem<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('${item} didUpdateWidget');
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<T>(
      data: item,
      feedback: widgetFromBuilder,
      axis: null,
      onDragUpdate: onDragUpdate,
      childWhenDragging: getChildWhenDragging(),
      onDragEnd: onDragEnd,
      onDragStarted: onDragStarted,
      onDraggableCanceled: onDraggableCanceled,
      onDragCompleted: onDragCompleted,
      dragAnchorStrategy: dragAnchorStrategy,
      child: DragTargetItem<T>(
          widgetFromBuilder: widgetFromBuilder,
          itemSize: itemSize,
          itemBox: itemBox,
          item: item,
          replaceItem: widget.replaceItem),
    );
  }

  ///
  Offset dragAnchorStrategy(
      Draggable<Object> draggable, BuildContext context, Offset position) {
    final RenderBox renderObject = context.findRenderObject()! as RenderBox;

    /// возвращаю обычный [childDragAnchorStrategy]
    return renderObject.globalToLocal(position);
  }

  ///
  void onDragEnd(DraggableDetails details) {
    isDragging = false;
  }

  ///
  void onDragStarted() {
    setState(() {
      isDragging = true;
    });
  }

  ///
  void onDraggableCanceled(velocity, offset) {
    isInParentBox = true;
    setTempHeight(itemSize.height);

    /// вызываю чтобы показать анимацию возврата элемента в изначальное положение
    widget.replaceItem(
      itemToReplace: item,
      item: item,
      startOffset: offset,
      endOffset: itemBox.topLeft,
    );
  }

  ///
  void onDragCompleted() {
    isInParentBox = true;
    setTempHeight(itemSize.height);
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

    if (isInParentBox) {
      final isContainsItemBox = !itemBox.contains(details.localPosition);
      if (isInAnotherItem != isContainsItemBox) {
        setState(() {
          isInAnotherItem = isContainsItemBox;
        });
      }
      // print('isInAnotherItem $isInAnotherItem');
    }
  }

  ///
  Widget getChildWhenDragging() {
    print('getChildWhenDragging');
    if (isInAnotherItem) {
      print('isInAnotherItem');
      return TweenAnimationBuilder(
        tween: Tween<double>(begin: tempHeight, end: 0),
        onEnd: () {
          setTempHeight(itemSize.width);
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

    if (isInParentBox) {
      print('isInParentBox');

      return TweenAnimationBuilder(
        tween: Tween<double>(begin: tempHeight, end: itemSize.width),
        onEnd: () {
          setTempHeight(itemSize.width);
        },
        duration: const Duration(milliseconds: 300),
        builder: (context, width, child) {
          return Container(
            color: Colors.indigo,
            width: width,
            height: width,
          );
        },
      );
    } else {
      print('!!!!isInParentBox');

      return TweenAnimationBuilder(
        tween: Tween<double>(begin: itemSize.width, end: itemSize.width),
        // tween: Tween<double>(begin: itemSize.width, end: 0),
        onEnd: () {
          setTempHeight(0);
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
  void setItemParameters({required BuildContext context}) {
    setState(() {
      RenderBox itemRenderBox = context.findRenderObject()! as RenderBox;
      RenderBox parent = itemRenderBox.parent! as RenderBox;
      parentBox = getRectBox(parent);
      itemSize = itemRenderBox.size;
      tempHeight = itemSize.height;
      itemBox = getRectBox(itemRenderBox);
    });
  }

  ///
  void setTempHeight(double tempHeight) {
    this.tempHeight = tempHeight;
  }

  ///
  void setDefaultValues() {
    ///
    isInParentBox = true;

    ///
    itemSize = Size.zero;

    ///
    itemBox = Rect.zero;

    ///
    tempHeight = 0;

    ///
    isDragging = false;

    ///
    isInAnotherItem = false;
  }
}

///
class DragTargetItem<T extends Object> extends StatefulWidget {
  const DragTargetItem({
    required this.widgetFromBuilder,
    required this.replaceItem,
    super.key,
    required this.itemSize,
    required this.itemBox,
    required this.item,
  });

  ///
  final T item;

  ///
  final Widget widgetFromBuilder;

  ///
  final Size itemSize;

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

///
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
      tween: Tween<double>(begin: 0, end: widget.itemSize.width),
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
      tween: Tween<double>(begin: widget.itemSize.width, end: 0),
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

///
Rect getRectBox(RenderBox renderBox) {
  Rect box = renderBox.paintBounds;
  Offset topLeftGlobal = renderBox.localToGlobal(box.topLeft);
  Offset bottomRightGlobal = renderBox.localToGlobal(box.bottomRight);
  return Rect.fromLTRB(topLeftGlobal.dx, topLeftGlobal.dy, bottomRightGlobal.dx,
      bottomRightGlobal.dy);
}
