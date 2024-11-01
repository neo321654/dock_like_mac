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
class Dock<T> extends StatefulWidget {
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
class _DockState<T> extends State<Dock<T>> {
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

class DockItem<T> extends StatefulWidget {
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

class _DockItemState<T> extends State<DockItem<T>> {
  late Widget widgetFromBuilder;

  @override
  void initState() {
    super.initState();
    widgetFromBuilder =
        widget.builder(widget.item); // Create widget from builder function.
  }

  @override
  Widget build(BuildContext context) {
    return Draggable(
      data: T,
      feedback: widgetFromBuilder,
      onDragUpdate: (details) {},
      childWhenDragging: showChildWhenDragging(child: widgetFromBuilder),
      onDragEnd: (details) {},
      onDragStarted: () {},
      onDraggableCanceled: (velocity, offset) {},
      onDragCompleted: () {},
      dragAnchorStrategy: childDragAnchorStrategy,
      child: DragTarget(
        builder: builder,
        onWillAcceptWithDetails: onWillAcceptWithDetails,
      ),
    );
  }

  Widget builder(context, candidateData, rejectedData) {
        /// отображение когда входит нужный айтем
        if (candidateData.isNotEmpty && candidateData.first == T) {
          return showItemInDragTarget(child: widgetFromBuilder);
        }
        /// стандартное отображение
        return widgetFromBuilder;
      }

  Widget showItemInDragTarget({required Widget child}) {
    return Container(
      color: Colors.blueAccent,
      child: child,
    );
  }

  Widget showChildWhenDragging({required Widget child}) {
    return Container(
      color: Colors.greenAccent,
      child: child,
    );
  }

  bool onWillAcceptWithDetails(details){
    return true;
  }
}
