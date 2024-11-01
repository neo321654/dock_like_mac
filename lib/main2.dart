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
  late Widget widgetFromBuilder;

  @override
  void initState() {
    super.initState();
    widgetFromBuilder =
        widget.builder(widget.item); // Create widget from builder function.
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<T>(
      data: widget.item,
      feedback: widgetFromBuilder,
      axis: null,
      onDragUpdate: (d) {},
      childWhenDragging: getChildWhenDragging(),
      onDragEnd: (d) {},
      onDragStarted: () {},
      onDraggableCanceled: (velocity, offset) {},
      onDragCompleted: () {},
      dragAnchorStrategy:dragAnchorStrategy,
      child: DragTarget(
        builder: builder,
        onWillAcceptWithDetails: onWillAcceptWithDetails,
        onAcceptWithDetails: onAcceptWithDetails,
        onMove: onMove,
        onLeave: onLeave,
      ),
    );
  }

  Offset dragAnchorStrategy(Draggable<Object> draggable, BuildContext context, Offset position) {
      // RenderBox renderObject =
      // getRenderBoxObject(context)!;


      final RenderBox renderObject = context.findRenderObject()! as RenderBox;


      RenderBox parent = renderObject.parent!  as RenderBox;
      Rect parentBounds = parent.paintBounds;
      Offset topLeftGlobal = parent.localToGlobal(parentBounds.topLeft);
      Offset bottomRightGlobal = parent.localToGlobal(parentBounds.bottomRight);


      print(renderObject.parent?.paintBounds);
      renderObject.size;
      // Offset? offSet = getParentOffset(renderObject);
      //
      // if (offSet != null) {
      //   Offset ofToGlobal = renderObject.localToGlobal(offSet) - offSet;
      //   widget.setGlobalDeltaOffset(offSet);
      //   widget.setGlobalOffset(
      //       ofToGlobal);
      //
      //
      //   offsetOutOfBounds = renderObject
      //       .globalToLocal(position);
      // }
      renderObject.paintBounds;

      /// возвращаю обычный [childDragAnchorStrategy]
      return renderObject
          .globalToLocal(position);
    }

  void onMove(DragTargetDetails details) {}

  void onLeave(item) {

  }

  Widget builder(context, candidateData, rejectedData) {
    /// отображение когда входит нужный айтем
    if (candidateData.isNotEmpty && candidateData.first.runtimeType == T) {
      return getWidgetInDragTarget();
    }
    /// стандартное отображение
    return widgetFromBuilder;
  }

  Widget getWidgetInDragTarget() {
    return Container(
      color: Colors.blueAccent,
      child: widgetFromBuilder,
    );
  }

  Widget getChildWhenDragging() {
    return Container(
      color: Colors.greenAccent,
      child: widgetFromBuilder,
    );
  }

  bool onWillAcceptWithDetails(DragTargetDetails details) {
    print('onWillAcceptWithDetails ${details.offset}');
    return true;
  }

  onAcceptWithDetails(DragTargetDetails details) {
    widget.replaceItem(
      details.data,
      widget.item,
    );
    // print('onAcceptWithDetails ${details.offset}');
  }
}
