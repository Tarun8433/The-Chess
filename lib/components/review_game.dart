// widgets/review_widgets.dart
import 'package:flutter/material.dart';
import 'package:the_chess/components/move_history.dart';

// Review Button Widget
class ReviewButton extends StatelessWidget {
  final VoidCallback? startReview;
  final bool canStartReview;
  final bool isInReviewMode;

  const ReviewButton({
    super.key,
    this.startReview,
    required this.canStartReview,
    required this.isInReviewMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ElevatedButton.icon(
        onPressed: canStartReview ? startReview : null,
        icon: Icon(
          isInReviewMode ? Icons.close : Icons.history,
          size: 18,
          color: Colors.white,
        ),
        label: Text(
          isInReviewMode ? 'Exit Review' : 'Review',
          style: const TextStyle(fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isInReviewMode ? Colors.orange : Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

// Review Controls Widget
class ReviewControls extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool canGoBack;
  final bool canGoForward;
  final String currentMoveInfo;
  final VoidCallback? onExitReview;
  final VoidCallback? startReview;
  final bool canStartReview;
  final bool isInReviewMode;

  const ReviewControls({
    super.key,
    this.onPrevious,
    this.onNext,
    required this.canGoBack,
    required this.canGoForward,
    required this.currentMoveInfo,
    this.onExitReview,
    this.startReview,
    required this.canStartReview,
    required this.isInReviewMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isInReviewMode
              ? [Colors.orange[100]!, Colors.orange[50]!]
              : [Colors.grey, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(),
                child: IconButton(
                  onPressed: canStartReview ? startReview : onExitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isInReviewMode ? Colors.orange : Colors.blue,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(
                    isInReviewMode ? Icons.close : Icons.preview,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              Spacer(),
              // Previous Move Button
              IconButton(
                onPressed: canGoBack ? onPrevious : null,
                icon: const Icon(Icons.arrow_back_ios, size: 18),
              ),

              const SizedBox(width: 12),

              // Next Move Button
              IconButton(
                onPressed: canGoForward ? onNext : null,
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Move History List Widget
class MoveHistoryWidget extends StatelessWidget {
  final List<ChessMove> moveHistory;
  final int currentReviewIndex;
  final Function(int) onMoveSelected;
  final bool isInReviewMode;

  const MoveHistoryWidget({
    super.key,
    required this.moveHistory,
    required this.currentReviewIndex,
    required this.onMoveSelected,
    required this.isInReviewMode,
  });

  @override
  Widget build(BuildContext context) {
    if (moveHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Move List
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: moveHistory.length,
              itemBuilder: (context, index) {
                final move = moveHistory[index];
                final isSelected =
                    isInReviewMode && index == currentReviewIndex;
                final isEvenMove = index % 2 == 0;

                return GestureDetector(
                  onTap: isInReviewMode ? () => onMoveSelected(index) : null,
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : (isEvenMove
                              ? Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.3)
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.secondary
                            : (isEvenMove
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.5)
                                : Theme.of(context).colorScheme.outline),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            //'${index + 1}-${move.piece.type.toString().split('.').last.toUpperCase()}-

                            '${move.moveNotation}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Simple Review Status Banner
class ReviewStatusBanner extends StatelessWidget {
  final bool isInReviewMode;
  final String statusText;

  const ReviewStatusBanner({
    super.key,
    required this.isInReviewMode,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    // if (!isInReviewMode) {
    //   return const SizedBox.shrink();
    // }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isInReviewMode
              ? [Colors.orange[300]!, Colors.orange[200]!]
              : [Colors.grey, Colors.white],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            color: Colors.black,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
