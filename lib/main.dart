import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
          child: Dock<IconData>(
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
  /// List of [T] items being manipulated.
  late final List<T> _items = widget.items.toList();

  /// Global delta offset for dragging items.
  Offset globalDeltaOffset = Offset.infinite;

  /// Global offset for dragging items.
  Offset globalOffset = Offset.infinite;

  /// The item that is currently hidden during drag.
  T? _itemToHide;

  ///
  bool inDragTarget = false;

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
        children: _items.map((e) {
          return DockItem<T>(
            key: ValueKey(e),
            item: e,
            globalDeltaOffset: globalDeltaOffset,
            globalOffset: globalOffset,
            inDragTarget: inDragTarget,
            setGlobalOffset: setGlobalOffset,
            setGlobalDeltaOffset: setGlobalDeltaOffset,
            setInDragTarget: setInDragTarget,
            builder: widget.builder,
            onDrop: onDrop,
            isVisible: e != _itemToHide, // Determines visibility of the item.
          );
        }).toList(),
      ),
    );
  }

  /// Handles the drop action for reordering items in the dock.
  void onDrop(T itemToReplace, T item) {
    setState(() {
      int index = _items.indexOf(item);
      _items.remove(itemToReplace);
      _items.insert(index, itemToReplace);
    });
  }

  /// Sets the global delta offset during drag operations.
  void setGlobalDeltaOffset(Offset offset) {
    setState(() {
      globalDeltaOffset = offset;
    });
  }

  /// Sets the global offset during drag operations.
  void setGlobalOffset(Offset offset) {
    setState(() {
      globalOffset = offset;
    });
  }

  ///
  void setInDragTarget(bool inDragTarget) {
    setState(() {
      this.inDragTarget = inDragTarget;
    });
  }
}

/// A draggable item in the dock.
class DockItem<T extends Object> extends StatefulWidget {
  /// Creates a [DockItem].
  const DockItem({
    required this.item,
    required this.builder,
    required this.onDrop,
    required this.setGlobalDeltaOffset,
    required this.setGlobalOffset,
    required this.setInDragTarget,
    required this.globalDeltaOffset,
    required this.globalOffset,
    required this.inDragTarget,
    this.isVisible = true,
    super.key,
  });

  /// The item to be displayed in the dock.
  final T item;

  /// Builder function to create the widget representation of the provided [item].
  final Widget Function(T) builder;

  /// Callback function invoked when an item is dropped.
  final Function(T itemToRemove, T item) onDrop;

  /// Callback to set the global delta offset during dragging.
  final Function(Offset offset) setGlobalDeltaOffset;

  /// Callback to set the global offset during dragging.
  final Function(Offset offset) setGlobalOffset;

  ///
  final Function(bool inDragTarget) setInDragTarget;

  /// Current global delta offset during dragging.
  final Offset globalDeltaOffset;

  /// Current global offset during dragging.
  final Offset globalOffset;

  /// Visibility of the dock item. Defaults to true.
  final bool isVisible;

  ///
  final bool inDragTarget;

  @override
  State<DockItem<T>> createState() => _DockItemState<T>();
}

/// State for [DockItem], managing its behavior and appearance during drag operations.
class _DockItemState<T extends Object> extends State<DockItem<T>> {
  /// Indicates if the item is currently being dragged.
  bool isDragging = false;

  /// Holds the widget created by the builder function.
  late Widget widgetFromBuilder;

  /// Offset for animation when dragging ends.
  Offset offsetToDelta = Offset.zero;

  /// Offset for the position when leaving a target area.
  Offset offsetToLeave = Offset.zero;

  /// Offset for the position when accepting a drop.
  Offset offsetToAccept = Offset.zero;

  ///
  Offset offMove = Offset.zero;

  ///
    bool isRightPadding = false;

  ///
   double itemWidth = 64;

  ///
  Offset ofToGlobal = Offset.zero;

  ///
  Offset offsetOutOfBounds = Offset.zero;

  ///
   Offset ofFromStart = Offset.zero;

  ///
   bool isUnLimit = false;




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
      // Data passed during drag and drop operations.
      onDragStarted: () {
        // print('onDragStarted');

        setState(() {
          isDragging = true; // Set dragging state to true when drag starts.
          // isVisible = false; // Hide the item being dragged.
        });
      },
      onDragUpdate: (dragUpdateDetails) {
         // print('1 ${offsetOutOfBounds }');
        ofFromStart = dragUpdateDetails.localPosition - offsetOutOfBounds;

        //  print('2 ${ofFromStart}');
        // print('3 ${widget.globalOffset-ofFromStart}');
        Offset lim = widget.globalOffset-ofFromStart;
        if(lim.dx.abs()>itemWidth*0.9 && !widget.inDragTarget|| lim.dy.abs()>itemWidth*0.9&& !widget.inDragTarget){

          setState(() {
            isUnLimit = true;
          });
      }
        if(widget.inDragTarget){

          setState(() {
            isUnLimit = false;
          });
        }

        // else{
        //   setState(() {
        //     isUnLimit = false;
        //   });
        // }
        // print(isUnLimit);
      },
      onDragEnd: (details) {
        showOverlayAnimation(
            begin: details.offset, // Start position for overlay animation.
            end: widget.globalOffset, // End position for overlay animation.
            context: context);

        WidgetsBinding.instance.addPostFrameCallback((d) {
          widget.setInDragTarget(false);
        });

        // setState(() {
        //   isDragging = true; // Set dragging state to true when drag starts.
        //   // isVisible = false; // Hide the item being dragged.
        // });



        resetGlobalDelta(); // Reset delta offsets after drag ends.
      },
      onDragCompleted: () {
        isDragging = false; // Reset dragging state when drag completes.
        resetGlobalDelta(); // Reset delta offsets after drag completes.
      },
      onDraggableCanceled: (velocity, offset) {
        isDragging = false; // Reset dragging state if drag is canceled.
        resetGlobalDelta(); // Reset delta offsets after cancellation.
      },
      dragAnchorStrategy:
          (Draggable<Object> draggable, BuildContext context, Offset position) {
        RenderBox renderObject =
            getRenderBoxObject(context)!; // Get render object for positioning.

        Offset? offSet = getParentOffset(renderObject); // Get parent offset.

        if (offSet != null) {
          Offset ofToGlobal = renderObject.localToGlobal(offSet) - offSet;
          widget.setGlobalDeltaOffset(offSet); // Update global delta offset.
          widget.setGlobalOffset(
              ofToGlobal); // Update global offset based on position.


          offsetOutOfBounds = renderObject
              .globalToLocal(position);
          // print('GlobalDeltaOffset = $offSet');
          // print('GlobalOffset = $ofToGlobal');
        }

        return renderObject
            .globalToLocal(position); // Convert position to local coordinates.
      },
      childWhenDragging:
      (isUnLimit)?
      TweenAnimationBuilder<double>(
          curve: Curves.easeInQuint,
          tween: Tween<double>(
            begin: itemWidth,
            end: 0,
          ),
          duration: const Duration(milliseconds: 400),
          onEnd: () {
            setState(() {
              offMove = Offset.zero;

            });
          },
          builder: (context, width, child) {
            return SizedBox(width: width,height: width,);
          }
      ):
      SizedBox(width: itemWidth,height: itemWidth,),

      feedback: widgetFromBuilder,
      child: DragTarget<T>(

        builder: (BuildContext context, candidateData, rejectedData) {

          if (candidateData.isNotEmpty) {
            // print('inDragTarget');

            ///устанавливаю глобальный флаг что в меня вошли
            if (!widget.inDragTarget) {
              WidgetsBinding.instance.addPostFrameCallback((d) {
                widget.setInDragTarget(true);
              });
            }

            RenderBox renderBox = context.findAncestorRenderObjectOfType()!;

            ///
            ofToGlobal = renderBox.localToGlobal(Offset.zero);

            itemWidth = renderBox.size.width;

            ///
            Offset ofOfStart = widget.globalOffset - ofToGlobal;

            ///я рядом с точкой старта?
            if (ofOfStart.dx.abs() <= itemWidth) {
              return TweenAnimationBuilder<Offset>(
                curve: Curves.easeInQuint,
                tween: Tween<Offset>(
                  begin: Offset.zero,
                  end: ofOfStart,
                ),
                duration: const Duration(milliseconds: 400),
                onEnd: () {},
                builder: (context, offset, child) {
                  return Transform.translate(
                    offset: offset,
                    child: widgetFromBuilder,
                  );
                },
                child: widgetFromBuilder,
              );
            } else if(isUnLimit){
              print('if(isUnLimit)');
               isRightPadding = (ofToGlobal - offMove).dx.isNegative;
              // print('ofOfStart - offMove = ${ofToGlobal - offMove}');

              return Row(
                children: [
                  TweenAnimationBuilder<double>(
                    curve: Curves.easeInQuint,
                    tween: Tween<double>(
                      begin: 0,
                      end: itemWidth,
                    ),
                    duration: const Duration(milliseconds: 400),
                    onEnd: () {},
                    builder: (context, width, child) {
                      return Padding(
                        padding: EdgeInsets.only(
                            left: !isRightPadding ? width : 0,
                            right: isRightPadding ? width : 0),
                        child: widgetFromBuilder,
                      );
                    },
                  ),
                ],
              );
            }



          }


          // if(offMove!=Offset.zero){
          //
          //   // final bool isRightPadding = (ofToGlobal - offMove).dx.isNegative;
          //   // print('ofOfStart - offMove = ${ofToGlobal - offMove}');
          //
          //   return TweenAnimationBuilder<double>(
          //   curve: Curves.easeInQuint,
          //     tween: Tween<double>(
          //       begin: itemWidth,
          //       end: 0,
          //     ),
          //     duration: const Duration(milliseconds: 400),
          //     onEnd: () {
          //     setState(() {
          //       offMove = Offset.zero;
          //
          //     });
          //     },
          //     builder: (context, width, child) {
          //       return Padding(
          //         padding: EdgeInsets.only(
          //             left: !isRightPadding ? width:0,
          //             right: isRightPadding ?  width:0),
          //         child: widgetFromBuilder,
          //       );
          //     },
          //   );
          //
          // }

          return widgetFromBuilder;

        },
        onMove: (dragTargetDetails) {
          if (!widget.inDragTarget) {
            // print(' onMove: (dragTargetDetails) ${dragTargetDetails.offset}');

            setState(() {
              offMove = dragTargetDetails.offset;
            });
          }
        },
        onAcceptWithDetails: (data) {

          widget.setGlobalOffset(ofToGlobal);

          widget.onDrop(data.data, widget.item);
        },
        onLeave: (data) {
          // print('onLeave');
          WidgetsBinding.instance.addPostFrameCallback((d) {
            widget.setInDragTarget(false);
          }); },
      ),
    );
  }

  /// Retrieves the parent offset of a given [RenderBox].
  Offset? getParentOffset(RenderBox? renderObject) {
    if (renderObject == null) return null;

    BoxParentData? pData = findBoxParentData(renderObject);

    if (pData != null) return pData.offset;

    return null;
  }

  /// Finds and returns the [BoxParentData] of a given [RenderBox].
  BoxParentData? findBoxParentData(RenderBox? renderBox) {
    if (renderBox == null) return null;

    RenderObject? parent = renderBox.parent;

    if (parent == null) return null;

    while (parent != null) {
      var parentData = parent.parentData;
      if (parentData is BoxParentData) {
        return parentData;
      }
      parent = parent.parent;
    }
    return null;
  }

  /// Retrieves the [RenderBox] object from a given [BuildContext].
  RenderBox? getRenderBoxObject(BuildContext context) {
    RenderObject? renderObject = context.findRenderObject();
    if (renderObject != null && renderObject is RenderBox) {
      return renderObject;
    }
    return null;
  }

  /// Resets the global delta offsets to zero and updates state accordingly.
  void resetGlobalDelta() {
    offsetToDelta = Offset.zero;
    widget.setGlobalDeltaOffset(Offset.infinite);
  }

  /// Shows overlay animation during drag and drop operation.
  void showOverlayAnimation(
      {required Offset begin,
      required Offset end,
      required BuildContext context}) {
    OverlayEntry? overlayEntry;

    void removeOverlayEntry() {
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
            AnimatedOffsetWidget(
              begin: begin,
              end: end,
              duration: const Duration(milliseconds: 1000),
              onEnd: removeOverlayEntry,
              child: widgetFromBuilder,
              builder: (context, offset, child) {
                return Positioned(
                  top: offset.dy,
                  left: offset.dx,
                  child: widgetFromBuilder,
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

/// A widget that animates its position based on offsets during transitions.
class AnimatedOffsetWidget extends StatelessWidget {
  /// Builder function that receives both current animated value and its associated child. This allows you to customize how your animated value should be rendered.
  final ValueWidgetBuilder<Offset> builder;

  /// The starting position for animation transition.
  final Offset begin;

  /// The ending position for animation transition.
  final Offset end;

  /// Duration of the animation transition effect.
  final Duration duration;

  /// Child widget that will be animated during transition effects.
  final Widget child;

  /// Animation curve for transition effect. Defaults to [Curves.easeInOutExpo].
  final Curve curve;

  /// Callback function invoked when animation ends. Optional callback function.
  final void Function()? onEnd;

  const AnimatedOffsetWidget({
    super.key,
    required this.begin,
    required this.end,
    required this.duration,
    required this.child,
    required this.builder,
    this.curve = Curves.easeInOutExpo,
    this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      curve: curve,
      tween: Tween<Offset>(
        begin: begin,
        end: end,
      ),
      duration: duration,
      onEnd: onEnd,
      builder: builder,
      child: child,
    );
  }
}
