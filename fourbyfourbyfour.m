function bedlam_cube_viewer()
% BEDLAM_CUBE_VIEWER
% Interactive 3D Bedlam cube with DNA strand info.
%
% Click any visible face (in Strand Info mode) to POP OUT the whole
% polycube piece that face belongs to, exposing all interior faces.
% Click any face of the popped piece to see that unit cell's strands.
% Click the piece again (or press Escape) to snap it back.
%
% Controls:
%   [Rotate / Zoom]  — drag to rotate, scroll to zoom (default)
%   [Strand Info]    — click any face to pop out / inspect that piece
%   R / I keys       — switch modes
%   Escape           — snap back + close info panel

%You will need to modify this
EXCEL_PATH = '/Users/sandeepsawhney/Downloads/5x5x5_updated.xlsx';

%% --- Dark theme ------------------------------------------------------
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

POP_DIST   = 4.5;   % how far pieces fly out (in unit-cube lengths)
POP_FRAMES = 22;    % animation steps for pop-out
SNAP_FRAMES = 14;   % animation steps for snap-back

%% --- Load data -------------------------------------------------------
fprintf('Loading strand data from Excel...\n');
strand_db = load_strands(EXCEL_PATH);
fprintf('  Loaded %d strand entries.\n\n', strand_db.Count);

[piece_id, piece_colors, piece_names, piece_centroids] = build_pieces();

%% --- Figure ----------------------------------------------------------
fig = figure('Name','Bedlam Cube - DNA Strand Viewer', ...
             'Color',C.bg, 'Position',[20 20 1700 1020]);

% ---- Button bar ----
btn_h = 0.068;

uicontrol(fig, 'Style','text', 'String','Mode:', ...
    'Units','normalized', 'Position',[0.01 0.008 0.055 btn_h-0.01], ...
    'BackgroundColor',C.bg, 'ForegroundColor',C.fg, ...
    'HorizontalAlignment','right', 'FontSize',11, 'FontWeight','bold');

h_rot = uicontrol(fig, 'Style','togglebutton', 'String','Rotate / Zoom', ...
    'Units','normalized', 'Position',[0.075 0.008 0.14 btn_h-0.01], ...
    'Value',1, 'BackgroundColor',C.btn_rot, 'ForegroundColor',C.fg, ...
    'FontSize',11, 'FontWeight','bold', ...
    'TooltipString','Drag to rotate  |  Scroll to zoom');

h_info = uicontrol(fig, 'Style','togglebutton', 'String','Strand Info', ...
    'Units','normalized', 'Position',[0.225 0.008 0.13 btn_h-0.01], ...
    'Value',0, 'BackgroundColor',C.btn_off, 'ForegroundColor',C.fg, ...
    'FontSize',11, 'FontWeight','bold', ...
    'TooltipString','Click any face — whole piece flies out; click again to snap back');

uicontrol(fig, 'Style','text', ...
    'String','  R = Rotate    I = Info    Esc = Return piece + close panel', ...
    'Units','normalized', 'Position',[0.37 0.008 0.38 btn_h-0.015], ...
    'BackgroundColor',C.bg, 'ForegroundColor',C.fg2, ...
    'HorizontalAlignment','left', 'FontSize',9);

h_return = uicontrol(fig, 'Style','pushbutton', 'String','Return Piece', ...
    'Units','normalized', 'Position',[0.77 0.008 0.14 btn_h-0.01], ...
    'BackgroundColor',[0.45 0.12 0.12], 'ForegroundColor',C.fg, ...
    'FontSize',11, 'FontWeight','bold', 'Visible','off', ...
    'TooltipString','Snap the popped piece back into the cube  (or press Esc)');

% ---- 3D axes ----
ax = axes(fig, 'DataAspectRatio',[1 1 1], 'Box','on', ...
    'Units','normalized', 'OuterPosition',[0 btn_h 1 1-btn_h], ...
    'Color',C.ax, 'XColor',C.fg, 'YColor',C.fg, 'ZColor',C.fg, ...
    'GridColor',C.grid, 'GridAlpha',0.5);
hold(ax,'on'); grid(ax,'on');

%% --- Draw all 64 unit cubes -----------------------------------------
cube_center = [2 2 2];   % centroid of the 4x4x4 grid
piece_patches = cell(13,1);   % piece_patches{pid} = array of patch handles

for iz = 0:3
    for iy = 0:3
        for ix = 0:3
            pid   = piece_id(ix+1, iy+1, iz+1);
            color = piece_colors(pid, :);
            k     = ix + 5*iy + 25*iz;
            lines = make_info_lines(ix,iy,iz,k,pid,piece_names{pid},strand_db);
            new_patches = draw_cube(ax, ix,iy,iz, color, C.edge, pid, lines);
            piece_patches{pid} = [piece_patches{pid}, new_patches];
        end
    end
end

%% --- Explosion directions (piece centroid → away from cube center) --
piece_dirs = zeros(13,3);
for pid = 1:13
    d = piece_centroids(pid,:) - cube_center;
    n = norm(d);
    if n < 0.1,  d = [0 0 1]; n = 1; end   % fallback for centred pieces
    piece_dirs(pid,:) = d / n;
end

%% --- Lighting & camera -----------------------------------------------
camlight(ax,'right');
lighting(ax,'gouraud');
view(ax, 35, 25);
xlim(ax,[-5.5 9.5]); ylim(ax,[-5.5 9.5]); zlim(ax,[-5.5 9.5]);

%% --- Labels & legend ------------------------------------------------
xlabel(ax,'X','Color',C.fg);
ylabel(ax,'Y','Color',C.fg);
zlabel(ax,'Z (layer)','Color',C.fg);
title(ax,'Bedlam Cube  —  switch to Strand Info and click any face', ...
    'Color',C.fg,'FontSize',12,'FontWeight','bold');

for i = 1:13
    patch(ax,NaN,NaN,piece_colors(i,:),'EdgeColor',C.edge, ...
          'DisplayName',strtrim(piece_names{i}));
end
lg = legend(ax,'show','Location','eastoutside','FontSize',8);
lg.TextColor = C.fg;  lg.Color = C.panel_bg;  lg.EdgeColor = C.grid;

%% --- Floating info panel --------------------------------------------
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

%% --- Store shared state in figure -----------------------------------
setappdata(fig,'C',           C);
setappdata(fig,'r3d',         rotate3d(fig));
setappdata(fig,'h_rot',       h_rot);
setappdata(fig,'h_info',      h_info);
setappdata(fig,'h_panel',     h_panel);
setappdata(fig,'h_title',     h_title);
setappdata(fig,'h_list',      h_list);
setappdata(fig,'piece_patches', piece_patches);
setappdata(fig,'piece_dirs',  piece_dirs);
setappdata(fig,'active_piece',0);
setappdata(fig,'pop_dist',    POP_DIST);
setappdata(fig,'pop_frames',  POP_FRAMES);
setappdata(fig,'snap_frames', SNAP_FRAMES);
setappdata(fig,'h_return',    h_return);

r3d = getappdata(fig,'r3d');
r3d.Enable = 'on';
r3d.RotateStyle = 'orbit';

h_rot.Callback    = @(~,~) switch_mode(fig,'rotate');
h_info.Callback   = @(~,~) switch_mode(fig,'info');
h_return.Callback = @(~,~) return_piece(fig);
fig.KeyPressFcn          = @(~,evt) key_handler(evt.Key,fig);
fig.WindowScrollWheelFcn = @(~,evt) scroll_zoom(evt,ax);

fprintf('Ready!  Drag to rotate.  Switch to Strand Info and click any face.\n');
end


%% =================================================================
%  Mode switching
%% =================================================================
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

function key_handler(key, fig)
switch lower(key)
    case 'r',      switch_mode(fig,'rotate');
    case 'i',      switch_mode(fig,'info');
    case 'escape', return_piece(fig);
                   set(getappdata(fig,'h_panel'),'Visible','off');
end
end


%% =================================================================
%  Scroll-wheel zoom — works in both Rotate and Info modes
%% =================================================================
function scroll_zoom(evt, ax)
% Zoom toward/away from the current camera target.
% VerticalScrollCount > 0  → scroll down → zoom out
% VerticalScrollCount < 0  → scroll up   → zoom in
factor = 1.12 ^ double(evt.VerticalScrollCount);
camzoom(ax, 1/factor);
end


%% =================================================================
%  Minimize / expand info panel
%% =================================================================
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


%% =================================================================
%  Draw one unit cube — returns the 6 new patch handles
%% =================================================================
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

fig    = ax.Parent;
handles = gobjects(1,6);

for f = 1:6
    p = patch('Vertices',V,'Faces',F(f,:), ...
              'FaceColor',color,'EdgeColor',edge_color,'LineWidth',0.7, ...
              'FaceLighting','gouraud','Parent',ax);
    p.UserData = struct('lines',{lines},'pid',pid,'base_verts',V);
    p.ButtonDownFcn = @(src,~) face_clicked(src,fig);
    handles(f) = p;
end
end


%% =================================================================
%  Face-click handler — pops out the whole piece
%% =================================================================
function face_clicked(src, fig)
ud = src.UserData;
if ~isstruct(ud), return; end

clicked_pid = ud.pid;
active      = getappdata(fig,'active_piece');
piece_dirs  = getappdata(fig,'piece_dirs');
pop_dist    = getappdata(fig,'pop_dist');
pop_frames  = getappdata(fig,'pop_frames');
snap_frames = getappdata(fig,'snap_frames');

if active == clicked_pid
    % Piece is already out — just show this cell's strands, stay out
    update_panel(fig, ud.lines);
    return;
end

% Different piece (or none active) — snap back current, pop new one
if active ~= 0
    snap_instant(fig, active, piece_dirs(active,:));
end

% Pop out the clicked piece
animate_piece(fig, clicked_pid, piece_dirs(clicked_pid,:), ...
              0, pop_dist, pop_frames);
setappdata(fig,'active_piece', clicked_pid);

% Show strand info for the first clicked cell
update_panel(fig, ud.lines);

% Reveal the Return button
h_return = getappdata(fig,'h_return');
if isvalid(h_return), h_return.Visible = 'on'; end
end


%% =================================================================
%  Return the active piece to the cube (animated) + hide Return btn
%% =================================================================
function return_piece(fig)
active     = getappdata(fig,'active_piece');
piece_dirs = getappdata(fig,'piece_dirs');
snap_frames = getappdata(fig,'snap_frames');
pop_dist    = getappdata(fig,'pop_dist');
h_return    = getappdata(fig,'h_return');

if active ~= 0
    animate_piece(fig, active, piece_dirs(active,:), pop_dist, 0, snap_frames);
    setappdata(fig,'active_piece', 0);
end
if isvalid(h_return), h_return.Visible = 'off'; end
end

function snap_instant(fig, pid, dir)
pp = getappdata(fig,'piece_patches');
for j = 1:numel(pp{pid})
    p = pp{pid}(j);
    if isvalid(p)
        p.Vertices = p.UserData.base_verts;
    end
end
drawnow limitrate;
end


%% =================================================================
%  Smooth animation: move piece from from_dist to to_dist along dir
%% =================================================================
function animate_piece(fig, pid, dir, from_dist, to_dist, n_frames)
pp = getappdata(fig,'piece_patches');
patches = pp{pid};

for frame = 1:n_frames
    t   = frame / n_frames;
    % Ease in-out cubic
    t   = t^2 * (3 - 2*t);
    off = (from_dist + (to_dist - from_dist) * t) * dir;

    for j = 1:numel(patches)
        p = patches(j);
        if isvalid(p)
            p.Vertices = bsxfun(@plus, p.UserData.base_verts, off);
        end
    end
    drawnow limitrate;
end
end


%% =================================================================
%  Update the strand info panel
%% =================================================================
function update_panel(fig, lines)
h_panel = getappdata(fig,'h_panel');
h_title = getappdata(fig,'h_title');
h_list  = getappdata(fig,'h_list');
POS_EXP = [0.63 0.20 0.365 0.75];

if isempty(lines) || ~iscell(lines), return; end

h_title.String = lines{1};
h_list.String  = lines(2:end);
h_list.Value   = 1;

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


%% =================================================================
%  Build info lines for one unit cell
%% =================================================================
function lines = make_info_lines(ix,iy,iz,k,pid,pname,strand_db)
face_note = {'','','','','','',''};
if ix==0, face_note{4}='  [X- face SE]'; end
if iy==0, face_note{5}='  [Y- face SE]'; end
if iz==0, face_note{3}='  [Z- bottom SE]'; end

lines = { ...
    sprintf('Piece: %s', pname), ...
    sprintf('Position:  x=%d   y=%d   z=%d   (unit k=%d)', ix,iy,iz,k), ...
    '─────────────────────────────────────────', ...
    'DNA Strands  (7 per tensegrity triangle):' ...
};

for off = 1:7
    sn = int32(7*k + off);
    if isKey(strand_db, sn)
        e     = strand_db(sn);
        sname = e{1};  sseq = e{2};
        if numel(sseq) > 42, sdisp = [sseq(1:42) '...']; else, sdisp = sseq; end
        lines{end+1} = sprintf('[%d] %s%s', off, sname, face_note{off}); %#ok<AGROW>
        lines{end+1} = sprintf('    %s', sdisp);                         %#ok<AGROW>
        lines{end+1} = '';                                                %#ok<AGROW>
    else
        lines{end+1} = sprintf('[%d] Strand%d  (not found)', off, sn);  %#ok<AGROW>
        lines{end+1} = '';                                                %#ok<AGROW>
    end
end
end


%% =================================================================
%  Load strand sequences
%% =================================================================
function db = load_strands(excel_path)
db = containers.Map('KeyType','int32','ValueType','any');

T = safe_readtable(excel_path, 'Core');
for r = 2:height(T)
    nm = to_str(T{r,1});  seq = to_str(T{r,2});
    if isempty(nm)||isempty(seq)||seq(1)=='=', continue; end
    n = strand_num(nm);
    if ~isnan(n), db(int32(n)) = {nm,seq}; end
end
fprintf('  Core: %d strands.\n', db.Count);

cnt0 = db.Count;
for sht = {'X_SE','Y_SE','Z_SE'}
    T = safe_readtable(excel_path, sht{1});
    for r = 1:height(T)
        for col = [1 4]
            if width(T) < col+1, continue; end
            nm = to_str(T{r,col});  seq = to_str(T{r,col+1});
            if isempty(nm)||isempty(seq)||seq(1)=='=', continue; end
            n = strand_num(nm);
            if ~isnan(n), db(int32(n)) = {nm,seq}; end
        end
    end
end
fprintf('  SE sheets: %d additional strands.\n', db.Count-cnt0);
end

% Read a sheet robustly across MATLAB versions, forcing all columns to text.
function T = safe_readtable(path, sheet)

% Best: detectImportOptions lets us force every column to char before
% readtable ever runs type inference (R2019a+).
try
    opts = detectImportOptions(path, 'Sheet', sheet);
    opts.VariableNamesRange = '';
    opts.DataRange          = 'A1';
    opts                    = setvartype(opts, opts.VariableNames, 'char');
    T = readtable(path, opts);
    return;
catch
end

% Second: basic readtable without options (R2016b+). Type inference may
% drop a handful of cells — acceptable fallback.
try
    T = readtable(path,'Sheet',sheet,'ReadVariableNames',false);
    return;
catch
end

% Last resort: xlsread raw cell array (deprecated in R2023a but present
% in all older releases). Wraps into a table so T{r,col} still works.
try
    [~,~,raw] = xlsread(path, sheet);
    if isempty(raw), T = table(); return; end
    ncols = max(cellfun(@(r) numel(r), num2cell(raw,2)));
    for i = 1:size(raw,1)
        while size(raw,2) < ncols, raw{i,end+1} = ''; end
    end
    % Replace numeric NaN cells (empty Excel cells) with empty string
    for i = 1:numel(raw)
        if isnumeric(raw{i}) && isscalar(raw{i}) && isnan(raw{i})
            raw{i} = '';
        elseif isnumeric(raw{i})
            raw{i} = num2str(raw{i});
        end
    end
    T = cell2table(raw);
    return;
catch e
    warning('safe_readtable(%s): %s', sheet, e.message);
    T = table();
end
end

function s = to_str(v)
if iscell(v),       v=v{1}; end
if ischar(v),       s=strtrim(v);
elseif isstring(v), s=strtrim(char(v));
else,               s='';
end
end

function n = strand_num(name)
tok = regexp(name,'(?i)strand(\d+)','tokens','once');
if isempty(tok), n=NaN; else, n=str2double(tok{1}); end
end


%% =================================================================
%  Piece assignment + centroids
%% =================================================================
function [piece_id, piece_colors, piece_names, piece_centroids] = build_pieces()

piece_names = { ...
    'Brown  (block0)',  'Red    (block1)',  'Green  (block2)', ...
    'DkGreen(block3)',  'Purple (block4)',  'Gray   (block5)', ...
    'Orange (block6)',  'White  (block7)',  'LtGray (block8)', ...
    'LtBlue (block9)',  'Yellow (blockA)',  'Blue   (blockB)', ...
    'Pink   (blockC) [tetracube]' ...
};

piece_colors = [ ...
    0.60 0.40 0.20;  % 1  Brown
    1.00 0.20 0.20;  % 2  Red
    0.20 0.85 0.20;  % 3  Green
    0.00 0.55 0.00;  % 4  DkGreen
    0.80 0.40 1.00;  % 5  Purple
    0.58 0.58 0.58;  % 6  Gray
    1.00 0.60 0.00;  % 7  Orange
    0.87 0.87 0.87;  % 8  White
    0.72 0.72 0.72;  % 9  LtGray
    0.40 0.80 1.00;  % 10 LtBlue
    1.00 1.00 0.00;  % 11 Yellow
    0.15 0.50 1.00;  % 12 Blue
    1.00 0.65 0.80;  % 13 Pink
];

% [x y z piece_id] — 0-indexed; stored at (x+1,y+1,z+1)
data = [ ...
    0 0 0 13;  1 0 0  8;  2 0 0  8;  3 0 0  8;
    0 1 0  9;  1 1 0  9;  2 1 0 10;  3 1 0  8;
    0 2 0  9;  1 2 0  6;  2 2 0  6;  3 2 0  5;
    0 3 0  9;  1 3 0 12;  2 3 0  6;  3 3 0  6;
    0 0 1 13;  1 0 1 13;  2 0 1  1;  3 0 1  8;
    0 1 1  3;  1 1 1 13;  2 1 1 10;  3 1 1  5;
    0 2 1  3;  1 2 1 12;  2 2 1  5;  3 2 1  5;
    0 3 1  9;  1 3 1 12;  2 3 1  6;  3 3 1  5;
    0 0 2  3;  1 0 2  1;  2 0 2  1;  3 0 2 10;
    0 1 2  3;  1 1 2 11;  2 1 2 10;  3 1 2 10;
    0 2 2 11;  1 2 2 11;  2 2 2  7;  3 2 2  4;
    0 3 2 12;  1 3 2 12;  2 3 2  4;  3 3 2  4;
    0 0 3  3;  1 0 3  2;  2 0 3  1;  3 0 3  1;
    0 1 3  2;  1 1 3  2;  2 1 3  2;  3 1 3  4;
    0 2 3 11;  1 2 3  2;  2 2 3  7;  3 2 3  4;
    0 3 3 11;  1 3 3  7;  2 3 3  7;  3 3 3  7;
];

piece_id = zeros(4,4,4,'uint8');
for r = 1:size(data,1)
    piece_id(data(r,1)+1, data(r,2)+1, data(r,3)+1) = data(r,4);
end

% Compute centroid of each piece (in unit-cube space, 0-indexed)
piece_centroids = zeros(13,3);
piece_count     = zeros(13,1);
for r = 1:size(data,1)
    pid = data(r,4);
    piece_centroids(pid,:) = piece_centroids(pid,:) + [data(r,1)+0.5, data(r,2)+0.5, data(r,3)+0.5];
    piece_count(pid)       = piece_count(pid) + 1;
end
for i = 1:13
    piece_centroids(i,:) = piece_centroids(i,:) / piece_count(i);
end
end
