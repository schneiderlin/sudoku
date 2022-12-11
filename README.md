# main.tscn
主场景

# chess_board.tscn
处理游戏逻辑

TODO:
后续要做成3种模式
- 单机模式, 移动完黑棋可以移动白棋, 可以回退和修改历史  √
- 回放模式, 不能做任何移动, 可以回退历史
- 联机模式, 移动完黑棋需要等对手移动白棋, 可以回退不能修改历史

# channel_panel.tscn
处理联机

TODO:
增加游戏大厅

# history_control.tscn
处理历史回放和修改

当history点击的时候, 计算出新的game state, 给chess_board显示