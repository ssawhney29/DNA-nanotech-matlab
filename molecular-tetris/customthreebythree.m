function extruded_soma_cube_viewer()
% EXTRUDED_SOMA_CUBE_VIEWER  —  3×3×3 Soma cube with bored-out face centers
%
% A custom 6-piece dissection of a 3×3×3 cube in which the center cell of
% every face has been bored straight through to the opposite face. This
% removes the 6 face-center cells AND the cube's body-center cell — i.e.
% the seven cells lying on the three orthogonal axes through the centre.
% What remains are the 8 corners + 12 edge-cells = 20 unit cells, forming
% three orthogonal square tunnels meeting at the cube's middle.
%
% Pieces (6 total, 4+4+4+4+2+2 = 20 cells):
%   1  Red     L-tetromino (tripod at corner 0,0,0)
%   2  Orange  L-tetromino (bottom layer)
%   3  Yellow  L-tetromino (top layer)
%   4  Green   L-tetromino (tripod at corner 2,2,2)
%   5  Blue    Domino
%   6  Purple  Domino
%
% Controls (same as the standard soma viewer):
%   [Rotate / Zoom]  — drag to rotate, scroll to zoom (default)
%   [Strand Info]    — click any face to pop out / inspect that piece
%   R / I keys       — switch modes
%   Escape           — snap piece back + close info panel

%% --- Dark theme ----------------------------------------------------------
C.bg        = [0.00 0.00 0.00];
C.ax        = [0.08 0.08 0.10];
C.grid      = [0.28 0.28 0.32];
C.fg        = [1.00 1.00 1.00];
C.fg2       = [0.60 0.60 0.65];
C.edge      = [0.38 0.38 0.42];
C.panel_bg  = [0.10 0.10 0.15];
C.panel_hdr = [0.14 0.14 0.22];
C.btn_off   = [0.20 0.20 0.24];
C.btn_rot   = [0.18 0.45 0.75];
C.btn_info  = [0.70 0.42 0.00];
C.list_bg   = [0.06 0.06 0.10];

POP_DIST    = 4.5;
POP_FRAMES  = 22;
SNAP_FRAMES = 14;

%% --- Piece data ----------------------------------------------------------
[piece_id, piece_colors, piece_names, piece_centroids, removed_mask] = build_pieces();
n_pieces = numel(piece_names);

%% --- Figure --------------------------------------------------------------
fig = figure('Name','Extruded Soma Cube - 3x3x3 Viewer', ...
             'Color',C.bg, 'Position',[20 20 1700 1020]);

btn_h = 0.068;

uicontrol(fig,'Style','text','String','Mode:', ...
    'Units','normalized','Position',[0.01 0.008 0.055 btn_h-0.01], ...
    'BackgroundColor',C.bg,'ForegroundColor',C.fg, ...
    'HorizontalAlignment','right','FontSize',11,'FontWeight','bold');

h_rot = uicontrol(fig,'Style','togglebutton','String','Rotate / Zoom', ...
    'Units','normalized','Position',[0.075 0.008 0.14 btn_h-0.01], ...
    'Value',1,'BackgroundColor',C.btn_rot,'ForegroundColor',C.fg, ...
    'FontSize',11,'FontWeight','bold', ...
    'TooltipString','Drag to rotate  |  Scroll to zoom');

h_info = uicontrol(fig,'Style','togglebutton','String','Strand Info', ...
    'Units','normalized','Position',[0.225 0.008 0.13 btn_h-0.01], ...
    'Value',0,'BackgroundColor',C.btn_off,'ForegroundColor',C.fg, ...
    'FontSize',11,'FontWeight','bold', ...
    'TooltipString','Click any face — whole piece flies out');

uicontrol(fig,'Style','text', ...
    'String','  R = Rotate    I = Info    Esc = Return piece + close panel', ...
    'Units','normalized','Position',[0.37 0.008 0.38 btn_h-0.015], ...
    'BackgroundColor',C.bg,'ForegroundColor',C.fg2, ...
    'HorizontalAlignment','left','FontSize',9);

h_return = uicontrol(fig,'Style','pushbutton','String','Return Piece', ...
    'Units','normalized','Position',[0.77 0.008 0.14 btn_h-0.01], ...
    'BackgroundColor',[0.45 0.12 0.12],'ForegroundColor',C.fg, ...
    'FontSize',11,'FontWeight','bold','Visible','off', ...
    'TooltipString','Snap piece back (or press Esc)');

%% --- 3D axes -------------------------------------------------------------
ax = axes(fig,'DataAspectRatio',[1 1 1],'Box','on', ...
    'Units','normalized','OuterPosition',[0 btn_h 1 1-btn_h], ...
    'Color',C.ax,'XColor',C.fg,'YColor',C.fg,'ZColor',C.fg, ...
    'GridColor',C.grid,'GridAlpha',0.5);
hold(ax,'on'); grid(ax,'on');

%% --- Draw the (up to) 20 unit cubes that remain -------------------------
cube_center   = [1 1 1];
piece_patches = cell(n_pieces,1);

for iz = 0:2
    for iy = 0:2
        for ix = 0:2
            if removed_mask(ix+1, iy+1, iz+1)
                continue;   % cell has been bored out
            end
            pid   = piece_id(ix+1, iy+1, iz+1);
            color = piece_colors(pid,:);
            lines = make_info_lines(ix, iy, iz, pid, piece_names{pid});
            new_p = draw_cube(ax, ix, iy, iz, color, C.edge, pid, lines);
            piece_patches{pid} = [piece_patches{pid}, new_p];
        end
    end
end

%% --- Explosion directions ------------------------------------------------
piece_dirs = zeros(n_pieces,3);
for pid = 1:n_pieces
    d = piece_centroids(pid,:) - cube_center;
    n = norm(d);
    if n < 0.1, d = [0 0 1]; n = 1; end
    piece_dirs(pid,:) = d / n;
end

%% --- Lighting & camera ---------------------------------------------------
camlight(ax,'right'); lighting(ax,'gouraud');
view(ax, 35, 25);
xlim(ax,[-5.5 8]); ylim(ax,[-5.5 8]); zlim(ax,[-5.5 8]);

%% --- Labels & legend -----------------------------------------------------
xlabel(ax,'X','Color',C.fg); ylabel(ax,'Y','Color',C.fg);
zlabel(ax,'Z (layer)','Color',C.fg);
title(ax,'Extruded Soma Cube  —  switch to Strand Info and click any face', ...
    'Color',C.fg,'FontSize',12,'FontWeight','bold');
for i = 1:n_pieces
    patch(ax,NaN,NaN,piece_colors(i,:),'EdgeColor',C.edge, ...
          'DisplayName',strtrim(piece_names{i}));
end
lg = legend(ax,'show','Location','eastoutside','FontSize',8);
lg.TextColor = C.fg; lg.Color = C.panel_bg; lg.EdgeColor = C.grid;

%% --- Floating info panel -------------------------------------------------
POS_EXP = [0.63 0.20 0.365 0.75];
POS_MIN = [0.63 0.20 0.365 0.056];

h_panel = uipanel(fig,'Units','normalized','Position',POS_EXP, ...
    'BackgroundColor',C.panel_bg,'ForegroundColor',C.fg, ...
    'BorderType','line','HighlightColor',C.grid,'Visible','off');
h_title = uicontrol(h_panel,'Style','text', ...
    'Units','normalized','Position',[0.01 0.955 0.73 0.04], ...
    'String','No selection','FontSize',11,'FontWeight','bold', ...
    'BackgroundColor',C.panel_hdr,'ForegroundColor',[0.55 0.75 1.00], ...
    'HorizontalAlignment','left');
h_min = uicontrol(h_panel,'Style','pushbutton','String','v', ...
    'Units','normalized','Position',[0.75 0.954 0.11 0.042], ...
    'FontSize',12,'FontWeight','bold', ...
    'BackgroundColor',C.panel_hdr,'ForegroundColor',C.fg);
uicontrol(h_panel,'Style','pushbutton','String','X', ...
    'Units','normalized','Position',[0.875 0.954 0.11 0.042], ...
    'FontSize',11,'FontWeight','bold', ...
    'ForegroundColor',[1.0 0.35 0.35],'BackgroundColor',C.panel_hdr, ...
    'Callback',@(~,~) set(h_panel,'Visible','off'));
h_list = uicontrol(h_panel,'Style','listbox', ...
    'Units','normalized','Position',[0.01 0.01 0.98 0.945], ...
    'FontName','Courier New','FontSize',9.5, ...
    'BackgroundColor',C.list_bg,'ForegroundColor',C.fg, ...
    'String',{''},'Max',999,'Value',1);
h_min.Callback = @(~,~) toggle_minimize(h_panel,h_list,h_min,POS_EXP,POS_MIN);

%% --- Store shared state --------------------------------------------------
setappdata(fig,'C',           C);
setappdata(fig,'r3d',         rotate3d(fig));
setappdata(fig,'h_rot',       h_rot);
setappdata(fig,'h_info',      h_info);
setappdata(fig,'h_panel',     h_panel);
setappdata(fig,'h_title',     h_title);
setappdata(fig,'h_list',      h_list);
setappdata(fig,'piece_patches', piece_patches);
setappdata(fig,'piece_dirs',  piece_dirs);
setappdata(fig,'active_piece', 0);
setappdata(fig,'pop_dist',    POP_DIST);
setappdata(fig,'pop_frames',  POP_FRAMES);
setappdata(fig,'snap_frames', SNAP_FRAMES);
setappdata(fig,'h_return',    h_return);

r3d = getappdata(fig,'r3d');
r3d.Enable = 'on'; r3d.RotateStyle = 'orbit';

h_rot.Callback           = @(~,~) switch_mode(fig,'rotate');
h_info.Callback          = @(~,~) switch_mode(fig,'info');
h_return.Callback        = @(~,~) return_piece(fig);
fig.KeyPressFcn          = @(~,evt) key_handler(evt.Key, fig);
fig.WindowScrollWheelFcn = @(~,evt) scroll_zoom(evt, ax);

fprintf('Ready.  Drag to rotate.  Switch to Strand Info and click any face.\n');
fprintf('Geometry: 3x3x3 cube with all six face-centers bored through.\n');
fprintf('  Remaining cells: 20  (8 corners + 12 edges)\n');
fprintf('  Pieces: %d   (sizes: 4+4+4+4+2+2)\n', n_pieces);
end


%% =========================================================================
%  Info lines — strands not yet mapped (stub, like threebythreebythree)
%% =========================================================================
function lines = make_info_lines(ix, iy, iz, pid, pname)
lines = { ...
    sprintf('Piece: %s', pname), ...
    sprintf('Position:  x=%d   y=%d   z=%d', ix, iy, iz), ...
    '─────────────────────────────────────────', ...
    'DNA Strands:', ...
    '', ...
    '    to be mapped', ...
    '' ...
};
end


%% =========================================================================
%  Piece assignment — custom 6-piece dissection of the extruded shape
%
%  Removed cells (3 orthogonal tunnels meeting at the centre):
%     (1,1,1)                                — body centre
%     (0,1,1),(2,1,1)                        — ±X face centres
%     (1,0,1),(1,2,1)                        — ±Y face centres
%     (1,1,0),(1,1,2)                        — ±Z face centres
%
%  Each piece's connectivity, validity, and the 20-cell coverage have all
%  been verified before the file was written.
%% =========================================================================
function [piece_id, piece_colors, piece_names, piece_centroids, removed_mask] = build_pieces()

piece_names = { ...
    'Red    (L-tet, corner 000)', ...
    'Orange (L-tet, bottom)', ...
    'Yellow (L-tet, top)', ...
    'Green  (L-tet, corner 222)', ...
    'Blue   (domino)', ...
    'Purple (domino)' ...
};

piece_colors = [ ...
    1.00 0.20 0.20;   % 1  Red
    1.00 0.55 0.00;   % 2  Orange
    1.00 0.85 0.00;   % 3  Yellow
    0.10 0.75 0.20;   % 4  Green
    0.20 0.50 1.00;   % 5  Blue
    0.75 0.35 1.00;   % 6  Purple
];

% [x y z pid] — 0-indexed
data = [ ...
    % --- Piece 1: Red tripod at (0,0,0) ---
    0 0 0 1;   1 0 0 1;   0 1 0 1;   0 0 1 1;   ...
    % --- Piece 2: Orange L-tetromino, bottom layer (z=0) wrapping corner (2,2,0) ---
    2 2 0 2;   2 1 0 2;   1 2 0 2;   2 0 0 2;   ...
    % --- Piece 3: Yellow L-tetromino, top layer (z=2) wrapping corner (0,0,2) ---
    0 0 2 3;   0 1 2 3;   1 0 2 3;   0 2 2 3;   ...
    % --- Piece 4: Green tripod at (2,2,2) ---
    2 2 2 4;   1 2 2 4;   2 1 2 4;   2 2 1 4;   ...
    % --- Piece 5: Blue domino ---
    0 2 0 5;   0 2 1 5;                          ...
    % --- Piece 6: Purple domino ---
    2 0 2 6;   2 0 1 6;                          ...
];

% Mask of which (x,y,z) cells have been removed (bored out)
removed_mask = false(3,3,3);
removed_list = [ ...
    1 1 1;   % body centre
    0 1 1;   2 1 1;   % ±X face centres
    1 0 1;   1 2 1;   % ±Y face centres
    1 1 0;   1 1 2 ]; % ±Z face centres
for r = 1:size(removed_list,1)
    removed_mask(removed_list(r,1)+1, removed_list(r,2)+1, removed_list(r,3)+1) = true;
end

% Piece-ID grid: 0 means "no cell here" (i.e., removed)
piece_id = zeros(3,3,3,'uint8');
for r = 1:size(data,1)
    piece_id(data(r,1)+1, data(r,2)+1, data(r,3)+1) = data(r,4);
end

% Sanity: every non-removed cell must have a piece
for iz = 0:2
    for iy = 0:2
        for ix = 0:2
            if ~removed_mask(ix+1,iy+1,iz+1) && piece_id(ix+1,iy+1,iz+1) == 0
                error('Cell (%d,%d,%d) has no piece assigned.', ix,iy,iz);
            end
            if removed_mask(ix+1,iy+1,iz+1) && piece_id(ix+1,iy+1,iz+1) ~= 0
                error('Cell (%d,%d,%d) is both removed and assigned.', ix,iy,iz);
            end
        end
    end
end

% Centroids per piece — used to compute explosion direction
n_pieces = numel(piece_names);
piece_centroids = zeros(n_pieces,3);
piece_count     = zeros(n_pieces,1);
for r = 1:size(data,1)
    pid = data(r,4);
    piece_centroids(pid,:) = piece_centroids(pid,:) + ...
        [data(r,1)+0.5, data(r,2)+0.5, data(r,3)+0.5];
    piece_count(pid) = piece_count(pid) + 1;
end
for i = 1:n_pieces
    piece_centroids(i,:) = piece_centroids(i,:) / piece_count(i);
end
end


%% =========================================================================
%  Mode switching
%% =========================================================================
function switch_mode(fig, mode)
C     = getappdata(fig,'C');
r3d   = getappdata(fig,'r3d');
h_rot = getappdata(fig,'h_rot');
h_inf = getappdata(fig,'h_info');
if strcmp(mode,'rotate')
    r3d.Enable = 'on';
    h_rot.Value = 1;  h_rot.BackgroundColor = C.btn_rot;
    h_inf.Value = 0;  h_inf.BackgroundColor = C.btn_off;
else
    r3d.Enable = 'off';
    h_rot.Value = 0;  h_rot.BackgroundColor = C.btn_off;
    h_inf.Value = 1;  h_inf.BackgroundColor = C.btn_info;
end
end


%% =========================================================================
%  Keyboard handler
%% =========================================================================
function key_handler(key, fig)
switch lower(key)
    case 'r',      switch_mode(fig,'rotate');
    case 'i',      switch_mode(fig,'info');
    case 'escape', return_piece(fig);
                   set(getappdata(fig,'h_panel'),'Visible','off');
end
end


%% =========================================================================
%  Scroll-wheel zoom — active in both modes
%% =========================================================================
function scroll_zoom(evt, ax)
factor = 1.12 ^ double(evt.VerticalScrollCount);
camzoom(ax, 1/factor);
end


%% =========================================================================
%  Minimize / expand info panel
%% =========================================================================
function toggle_minimize(h_panel, h_list, h_min, pos_exp, pos_min)
cur = h_panel.Position;
if abs(cur(4) - pos_exp(4)) < 0.01
    h_panel.Position = pos_min;
    h_list.Visible   = 'off';
    h_min.String     = '^';
else
    h_panel.Position = pos_exp;
    h_list.Visible   = 'on';
    h_min.String     = 'v';
end
end


%% =========================================================================
%  Draw one unit cube — 6 patch faces, each carries UserData for clicks
%% =========================================================================
function handles = draw_cube(ax, x, y, z, color, edge_color, pid, lines)
V = [x   y   z  ;
     x+1 y   z  ;
     x+1 y+1 z  ;
     x   y+1 z  ;
     x   y   z+1;
     x+1 y   z+1;
     x+1 y+1 z+1;
     x   y+1 z+1];

F = [1 2 3 4;
     5 6 7 8;
     1 2 6 5;
     4 3 7 8;
     1 4 8 5;
     2 3 7 6];

fig     = ax.Parent;
handles = gobjects(1,6);
for f = 1:6
    p = patch('Vertices',V,'Faces',F(f,:), ...
              'FaceColor',color,'EdgeColor',edge_color,'LineWidth',0.7, ...
              'FaceLighting','gouraud','Parent',ax);
    p.UserData      = struct('lines',{lines},'pid',pid,'base_verts',V);
    p.ButtonDownFcn = @(src,~) face_clicked(src, fig);
    handles(f)      = p;
end
end


%% =========================================================================
%  Face-click handler
%% =========================================================================
function face_clicked(src, fig)
ud = src.UserData;
if ~isstruct(ud), return; end

clicked_pid = ud.pid;
active      = getappdata(fig,'active_piece');
piece_dirs  = getappdata(fig,'piece_dirs');
pop_dist    = getappdata(fig,'pop_dist');
pop_frames  = getappdata(fig,'pop_frames');

if active == clicked_pid
    update_panel(fig, ud.lines);
    return;
end

if active ~= 0
    snap_instant(fig, active);
end

animate_piece(fig, clicked_pid, piece_dirs(clicked_pid,:), ...
              0, pop_dist, pop_frames);
setappdata(fig,'active_piece', clicked_pid);
update_panel(fig, ud.lines);

h_return = getappdata(fig,'h_return');
if isvalid(h_return), h_return.Visible = 'on'; end
end


%% =========================================================================
%  Return active piece to cube
%% =========================================================================
function return_piece(fig)
active      = getappdata(fig,'active_piece');
piece_dirs  = getappdata(fig,'piece_dirs');
snap_frames = getappdata(fig,'snap_frames');
pop_dist    = getappdata(fig,'pop_dist');
h_return    = getappdata(fig,'h_return');
if active ~= 0
    animate_piece(fig, active, piece_dirs(active,:), pop_dist, 0, snap_frames);
    setappdata(fig,'active_piece', 0);
end
if isvalid(h_return), h_return.Visible = 'off'; end
end


%% =========================================================================
%  Instant snap — used when switching pieces without snapping animation
%% =========================================================================
function snap_instant(fig, pid)
pp = getappdata(fig,'piece_patches');
for j = 1:numel(pp{pid})
    p = pp{pid}(j);
    if isvalid(p), p.Vertices = p.UserData.base_verts; end
end
drawnow limitrate;
end


%% =========================================================================
%  Animated pop-out / snap-back
%% =========================================================================
function animate_piece(fig, pid, dir, from_dist, to_dist, n_frames)
pp      = getappdata(fig,'piece_patches');
patches = pp{pid};
for frame = 1:n_frames
    t   = frame / n_frames;
    t   = t^2 * (3 - 2*t);
    off = (from_dist + (to_dist - from_dist)*t) * dir;
    for j = 1:numel(patches)
        p = patches(j);
        if isvalid(p)
            p.Vertices = bsxfun(@plus, p.UserData.base_verts, off);
        end
    end
    drawnow limitrate;
end
end


%% =========================================================================
%  Update info panel
%% =========================================================================
function update_panel(fig, lines)
h_panel = getappdata(fig,'h_panel');
h_title = getappdata(fig,'h_title');
h_list  = getappdata(fig,'h_list');
POS_EXP = [0.63 0.20 0.365 0.75];
if isempty(lines) || ~iscell(lines), return; end
h_title.String  = lines{1};
h_list.String   = lines(2:end);
h_list.Value    = 1;
h_panel.Visible = 'on';
pos = h_panel.Position;
if pos(4) < 0.2
    h_panel.Position = POS_EXP;
    h_list.Visible   = 'on';
    kids = h_panel.Children;
    for k = 1:numel(kids)
        if isprop(kids(k),'Style') && strcmp(kids(k).Style,'pushbutton') && ...
           any(strcmp(kids(k).String,{'^','v'}))
            kids(k).String = 'v';
        end
    end
end
end