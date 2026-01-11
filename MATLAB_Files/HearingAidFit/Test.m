figure;

% Create 4 rows, 1 column tiled layout
t = tiledlayout(4,1);
t.TileSpacing = 'compact';
t.Padding = 'compact';

% First subplot (spans rows 1 and 2)
ax1 = nexttile([2 1]);  % 2 rows, 1 column span
plot(ax1, rand(10,1));
title(ax1, 'Subplot 1 (spans 2 rows)');

% Second subplot (row 3)
ax2 = nexttile;
plot(ax2, rand(10,1));
title(ax2, 'Subplot 2');

% Third subplot (row 4)
ax3 = nexttile;
plot(ax3, rand(10,1));
title(ax3, 'Subplot 3');