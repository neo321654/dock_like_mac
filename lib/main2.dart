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
  void replaceItem(T itemToReplace, T item) {
    setState(() {
      int index = _items.indexOf(item);
      _items.remove(itemToReplace);
      _items.insert(index, itemToReplace);
    });
  }
}

class DockItem<T extends Object> extends StatefulWidget {
  const DockItem(
      {required this.builder,
      required this.item,
      required this.replaceItem,
      super.key});

  final T item;

  final Widget Function(T) builder;

  /// Callback function invoked when an item is dropped.
  final Function(T itemToRemove, T item) replaceItem;

  @override
  State<DockItem<T>> createState() => _DockItemState<T>();
}

class _DockItemState<T extends Object> extends State<DockItem<T>> {
  ///
  late Widget widgetFromBuilder;

  ///
  late Rect parentBox;

  ///
  bool isInParentBox = true;

  ///
  Size itemSize = Size.zero;

  ///
  Rect itemBox = Rect.zero;

  ///
  double tempHeight = 0;

  @override
  void initState() {
    super.initState();
    widgetFromBuilder = widget.builder(widget.item);

    ///
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RenderBox itemRenderBox = context.findRenderObject()! as RenderBox;
      setItemParameters(itemRenderBox);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<T>(
      data: widget.item,
      feedback: widgetFromBuilder,
      axis: null,
      onDragUpdate: onDragUpdate,
      childWhenDragging: getChildWhenDragging(),
      onDragEnd: onDragEnd,
      onDragStarted: () {},
      onDraggableCanceled: (velocity, offset) {},
      onDragCompleted: () {},
      dragAnchorStrategy: dragAnchorStrategy,
      child: DragTarget(
        builder: dragTargetBuilder,

        ///bug on web
        onWillAcceptWithDetails: onWillAcceptWithDetails,
        onAcceptWithDetails: onAcceptWithDetails,

        ///bug on web
        onMove: onMove,
        onLeave: onLeave,
      ),
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
  void onMove(DragTargetDetails details) {
    // print('onMove ${details.offset}');
  }

  ///
  void onDragEnd(DraggableDetails details) {
    isInParentBox = true;
    setTempHeight(itemSize.height);
  }

  ///
  void onLeave(item) {}

  ///
  void onAcceptWithDetails(DragTargetDetails details) {
    widget.replaceItem(
      details.data,
      widget.item,
    );
  }

  ///
  void onDragUpdate(DragUpdateDetails details) {
    final isContains = parentBox.contains(details.localPosition);
    if (isInParentBox != isContains) {
      setState(() {
        isInParentBox = isContains;
      });
    }
  }

  ///
  Widget dragTargetBuilder(context, candidateData, rejectedData) {
    /// отображение когда входит нужный айтем
    if (candidateData.isNotEmpty && candidateData.first.runtimeType == T) {
      return getWidgetInDragTarget();
    }

    /// стандартное отображение
    return widgetFromBuilder;
  }

  ///
  Widget getWidgetInDragTarget() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: itemSize.width),
      duration: const Duration(milliseconds: 300),
      builder: (context, width, child) {
        return Container(
            color: Colors.red,
            child: Row(
              children: [
                Padding(
                  // padding: EdgeInsets.only(left: width),
                  padding: EdgeInsets.only(left: 0),
                  child: child,
                ),
              ],
            ));
      },
      child: widgetFromBuilder,
    );

    // return Container(
    //   color: Colors.blueAccent,
    //   child: widgetFromBuilder,
    // );
  }

  ///
  Widget getChildWhenDragging() {
    return isInParentBox
        ? TweenAnimationBuilder(
            tween: Tween<double>(begin: tempHeight, end: itemSize.width),
            onEnd: () {
              setTempHeight(itemSize.width);
            },
            duration: const Duration(milliseconds: 300),
            builder: (context, width, child) {
              return SizedBox(width: width);
            },
          )
        : TweenAnimationBuilder(
            tween: Tween<double>(begin: itemSize.width, end: 0),
            onEnd: () {
              setTempHeight(0);
            },
            duration: const Duration(milliseconds: 300),
            builder: (context, width, child) {
              return SizedBox(width: width);
            },
          );
  }

  ///
  bool onWillAcceptWithDetails(DragTargetDetails details) {
    // print('onWillAcceptWithDetails ${details.offset}');
    return true;
  }

  ///
  void setItemParameters(RenderBox itemRenderBox) {
    setState(() {
      RenderBox parent = itemRenderBox.parent! as RenderBox;
      parentBox = getRectBox(parent);
      itemSize = itemRenderBox.size;
      tempHeight = itemSize.height;
      itemBox = getRectBox(itemRenderBox);
    });
  }

  ///
  Rect getRectBox(RenderBox renderBox) {
    Rect box = renderBox.paintBounds;
    Offset topLeftGlobal = renderBox.localToGlobal(box.topLeft);
    Offset bottomRightGlobal = renderBox.localToGlobal(box.bottomRight);
    return Rect.fromLTRB(topLeftGlobal.dx, topLeftGlobal.dy,
        bottomRightGlobal.dx, bottomRightGlobal.dy);
  }

  ///
  void setItemData(Size itemSize) {
    setState(() {
      this.itemSize = itemSize;
    });
  }

  ///
  void setTempHeight(double tempHeight) {
    setState(() {
      this.tempHeight = tempHeight;
    });
  }
}
