import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 展開可能な説明文ウィジェット
/// 最初は3行まで表示し、タップで全文表示/折りたたみを切り替える
class ExpandableDescription extends StatefulWidget {
  /// 表示するテキスト内容
  final String text;
  
  /// タイトル（「説明」など）
  final String title;
  
  /// 初期状態で展開するかどうか
  final bool initiallyExpanded;
  
  /// 最大行数（展開前）
  final int maxLines;

  const ExpandableDescription({
    super.key,
    required this.text,
    required this.title,
    this.initiallyExpanded = false,
    this.maxLines = 3,
  });

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

/// 展開可能な説明文ウィジェットの状態管理クラス
/// 展開・折りたたみ状態とアニメーション効果を管理
class _ExpandableDescriptionState extends State<ExpandableDescription>
    with SingleTickerProviderStateMixin {
  /// 展開状態を管理するフラグ
  late bool _isExpanded;

  /// アニメーション制御用のコントローラー
  late AnimationController _animationController;

  /// アニメーション（回転効果用）
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // 初期展開状態を設定
    _isExpanded = widget.initiallyExpanded;
    
    // アニメーション設定
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: widget.initiallyExpanded ? 1.0 : 0.0, // 初期状態に応じてコントローラーの値を設定
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5, // 180度回転（0.5 = 180度）
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 展開・折りたたみを切り替えるメソッド
  /// アニメーション付きで状態を変更
  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _animationController.forward() : _animationController.reverse(); // 三項演算子で処理を一行に
    });
  }

  /// テキストが指定行数を超えているかチェック
  /// TextPainterを使用して実際の行数を計算
  bool _isTextOverflowing() {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: widget.text,
        style: const TextStyle(fontSize: 16), // デフォルトのテキストスタイル
      ),
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 64); // パディング考慮
    
    return textPainter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    // テキストが空の場合は何も表示しない
    if (widget.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // テキストが短い場合は展開ボタンを表示しない
    final isOverflowing = _isTextOverflowing();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトル部分
          Row(
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              
              // 展開ボタン（オーバーフローする場合のみ表示）
              if (isOverflowing) ...[
                const Spacer(),
                GestureDetector(
                  onTap: _toggleExpansion,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isExpanded ? '折りたたむ' : 'もっと見る',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedBuilder(
                        animation: _rotationAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationAnimation.value * math.pi, // π rad = 180度
                            child: Icon(
                              Icons.expand_more,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 4),
          
          // 説明文本体
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isExpanded || !isOverflowing
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            
            // 折りたたまれた状態（3行まで）
            firstChild: Text(
              widget.text,
              style: const TextStyle(fontSize: 16),
              maxLines: widget.maxLines,
              overflow: TextOverflow.ellipsis,
            ),
            
            // 展開された状態（全文表示）
            secondChild: Text(
              widget.text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
