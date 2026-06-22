function customfourbyfourbyfour()
% CUSTOMFOURBYFOURBYFOUR
% Blank-slate Bedlam cube solver with DNA strand info.
%
% The cube starts as 64 grey cells (no pieces).  You PAINT one Bedlam piece
% by clicking the cells it should occupy, then press SOLVE — the computer
% fills in the remaining 12 pieces (exact-cover backtracking search) and
% colours the cube with the first valid completion it finds.
%
% Strand mapping is identical to fourbyfourbyfour.m: the 4x4x4 cube is the
% interior of the 5x5x5 DNA design space, so cell (ix,iy,iz)=0..3 lives at
% DNA coordinate (dx,dy,dz)=1..4 and uses strands 7k+1..7k+7 where
%   k = dx + 5*dy + 25*dz.
%
% Modes:
%   [Rotate / Zoom]  drag to rotate, scroll to zoom
%   [Select Cells]   click cells to paint the piece you want to pin
%   [Strand Info]    click a solved face -> the whole piece pops out;
%                    click the popped piece to read a cell's 7 strands
% Buttons: SOLVE | CLEAR | Return Piece (or Esc to snap back)
% View Z:  isolate one layer so interior cells become clickable while painting

%You will need to modify this
EXCEL_PATH = 'molecular-tetris/1. 5X5X5 sequences unsorted.xlsx';

%% --- Theme -----------------------------------------------------------
C.bg        = [0.00 0.00 0.00];
C.ax        = [0.08 0.08 0.10];
C.grid      = [0.28 0.28 0.32];
C.fg        = [1.00 1.00 1.00];
C.fg2       = [0.60 0.60 0.65];
C.edge      = [0.38 0.38 0.42];
C.edge_sel  = [1.00 1.00 0.20];
C.panel_bg  = [0.10 0.10 0.15];
C.panel_hdr = [0.14 0.14 0.22];
C.list_bg   = [0.06 0.06 0.10];
C.grey      = [0.55 0.55 0.55];   % blank-slate cell colour
C.sel       = [0.10 0.85 0.95];   % painted/selected cell colour
C.btn_off   = [0.20 0.20 0.24];
C.btn_on    = [0.18 0.45 0.75];

SOL_CAP = 1;     % stop at the first completion found

POP_DIST   = 4.0;   % how far a piece flies out when inspected (unit-cube lengths)
POP_FRAMES = 18;    % pop-out animation steps
SNAP_FRAMES= 12;    % snap-back animation steps

%% --- Load strand data ------------------------------------------------
fprintf('Loading strand data from Excel...\n');
strand_db = load_strands(EXCEL_PATH);
fprintf('  Loaded %d strand entries.\n\n', strand_db.Count);

%% --- Piece definitions (shapes derived from the solved arrangement) --
[piece_colors, piece_names, data] = piece_table();
shapes = derive_shapes(data);                 % 13 base polycubes (0-indexed)
[cand_pid, cand_mask, cand_lin, piece_keys] = build_placements(shapes);

%% --- Figure ----------------------------------------------------------
fig = figure('Name','Custom Bedlam Cube - Solver + DNA Strands', ...
             'Color',C.bg, 'Position',[20 20 1700 1020], 'WindowState','maximized');

btn_h = 0.05; y0 = 0.008;
mkbtn = @(x,w,str,bc,tt) uicontrol(fig,'Style','togglebutton','String',str, ...
    'Units','normalized','Position',[x y0 w btn_h], ...
    'BackgroundColor',bc,'ForegroundColor',C.fg,'FontSize',10, ...
    'FontWeight','bold','TooltipString',tt);
mkpush = @(x,w,str,bc,tt) uicontrol(fig,'Style','pushbutton','String',str, ...
    'Units','normalized','Position',[x y0 w btn_h], ...
    'BackgroundColor',bc,'ForegroundColor',C.fg,'FontSize',10, ...
    'FontWeight','bold','TooltipString',tt);

h_rot  = mkbtn(0.008,0.092,'Rotate / Zoom',C.btn_on, 'Drag to rotate | scroll to zoom');
h_sel  = mkbtn(0.103,0.092,'Select Cells', C.btn_off,'Click cells to paint the piece to pin');
h_info = mkbtn(0.198,0.092,'Strand Info',  C.btn_off,'Click a face: pops the piece out; click again for strands');
h_rot.Value = 1;

h_solve  = mkpush(0.295,0.062,'SOLVE', [0.15 0.55 0.20],'Pin painted piece and fill the rest');
h_clear  = mkpush(0.359,0.062,'CLEAR', [0.45 0.12 0.12],'Clear selection and colours');
h_return = mkpush(0.423,0.082,'Return Piece',[0.45 0.12 0.12], ...
    'Snap the popped piece back (or press Esc)');

uicontrol(fig,'Style','text','String','View Z:','Units','normalized', ...
    'Position',[0.510 y0 0.040 btn_h-0.012],'BackgroundColor',C.bg, ...
    'ForegroundColor',C.fg,'FontSize',9.5,'FontWeight','bold', ...
    'HorizontalAlignment','right');
h_layer = uicontrol(fig,'Style','popupmenu', ...
    'String',{'All layers','Z = 0','Z = 1','Z = 2','Z = 3'}, ...
    'Units','normalized','Position',[0.553 y0 0.078 btn_h], ...
    'BackgroundColor',C.btn_off,'ForegroundColor',C.fg,'FontSize',9, ...
    'TooltipString','Isolate one layer to reach interior cells while painting');

h_status = uicontrol(fig,'Style','text','String','Paint a piece, then press SOLVE.', ...
    'Units','normalized','Position',[0.638 y0 0.355 btn_h-0.005], ...
    'BackgroundColor',C.bg,'ForegroundColor',C.fg2, ...
    'HorizontalAlignment','left','FontSize',9.5);

% ---- 3D axes ----
ax = axes(fig,'DataAspectRatio',[1 1 1],'Box','on', ...
    'Units','normalized','OuterPosition',[0 btn_h+0.012 1 1-btn_h-0.012], ...
    'Color',C.ax,'XColor',C.fg,'YColor',C.fg,'ZColor',C.fg, ...
    'GridColor',C.grid,'GridAlpha',0.5,'Clipping','off');
hold(ax,'on'); grid(ax,'on');

%% --- Draw 64 grey cells ---------------------------------------------
cube_patches = cell(1,64);
for iz = 0:3
    for iy = 0:3
        for ix = 0:3
            dx = ix+1; dy = iy+1; dz = iz+1;          % DNA coords (interior)
            lin1 = ix + 4*iy + 16*iz + 1;
            cube_patches{lin1} = draw_cube(ax, dx,dy,dz, C.grey, C.edge, ...
                                           struct('ix',ix,'iy',iy,'iz',iz,'lin1',lin1), fig);
        end
    end
end

camlight(ax,'right'); lighting(ax,'gouraud');
view(ax,35,25);
xlim(ax,[0.5 5.5]); ylim(ax,[0.5 5.5]); zlim(ax,[0.5 5.5]);
xlabel(ax,'X','Color',C.fg); ylabel(ax,'Y','Color',C.fg); zlabel(ax,'Z (layer)','Color',C.fg);
title(ax,'Blank slate — Select Cells, paint a piece, press SOLVE', ...
    'Color',C.fg,'FontSize',12,'FontWeight','bold');

%% --- Info panel ------------------------------------------------------
POS_EXP = [0.760 0.26 0.232 0.70];   % floats as an overlay on the right
h_panel = uipanel(fig,'Units','normalized','Position',POS_EXP, ...
    'BackgroundColor',C.panel_bg,'BorderType','line', ...
    'HighlightColor',C.grid,'Visible','off');
h_title = uicontrol(h_panel,'Style','text','Units','normalized', ...
    'Position',[0.01 0.955 0.85 0.04],'String','No selection', ...
    'FontSize',11,'FontWeight','bold','BackgroundColor',C.panel_hdr, ...
    'ForegroundColor',[0.55 0.75 1.00],'HorizontalAlignment','left');
uicontrol(h_panel,'Style','pushbutton','String','X','Units','normalized', ...
    'Position',[0.88 0.954 0.11 0.042],'FontSize',11,'FontWeight','bold', ...
    'ForegroundColor',[1 0.35 0.35],'BackgroundColor',C.panel_hdr, ...
    'Callback',@(~,~) set(h_panel,'Visible','off'));
h_list = uicontrol(h_panel,'Style','listbox','Units','normalized', ...
    'Position',[0.01 0.01 0.98 0.945],'FontName','Courier New','FontSize',9.5, ...
    'BackgroundColor',C.list_bg,'ForegroundColor',C.fg,'String',{''}, ...
    'Max',999,'Value',1);

%% --- Shared state ----------------------------------------------------
setappdata(fig,'C',C);
setappdata(fig,'strand_db',strand_db);
setappdata(fig,'piece_colors',piece_colors);
setappdata(fig,'piece_names',piece_names);
setappdata(fig,'cand_pid',cand_pid);
setappdata(fig,'cand_mask',cand_mask);
setappdata(fig,'cand_lin',cand_lin);
setappdata(fig,'piece_keys',piece_keys);
setappdata(fig,'cube_patches',{cube_patches});
setappdata(fig,'selection',false(1,64));
setappdata(fig,'cellpid',zeros(1,64));
setappdata(fig,'sol_cap',SOL_CAP);
setappdata(fig,'mode','rotate');
setappdata(fig,'active_piece',0);
setappdata(fig,'pop_dist',POP_DIST);
setappdata(fig,'pop_frames',POP_FRAMES);
setappdata(fig,'snap_frames',SNAP_FRAMES);
setappdata(fig,'r3d',rotate3d(fig));
setappdata(fig,'ax',ax);
setappdata(fig,'h_rot',h_rot);  setappdata(fig,'h_sel',h_sel);
setappdata(fig,'h_info',h_info); setappdata(fig,'h_layer',h_layer);
setappdata(fig,'h_panel',h_panel); setappdata(fig,'h_title',h_title);
setappdata(fig,'h_list',h_list);   setappdata(fig,'h_status',h_status);

r3d = getappdata(fig,'r3d'); r3d.Enable = 'on'; r3d.RotateStyle = 'orbit';

h_rot.Callback    = @(~,~) switch_mode(fig,'rotate');
h_sel.Callback    = @(~,~) switch_mode(fig,'select');
h_info.Callback   = @(~,~) switch_mode(fig,'info');
h_solve.Callback  = @(~,~) do_solve(fig);
h_clear.Callback  = @(~,~) do_clear(fig);
h_return.Callback = @(~,~) return_piece(fig);
h_layer.Callback  = @(src,~) set_layer(fig, src.Value);
fig.KeyPressFcn          = @(~,evt) key_handler(evt.Key, fig);
fig.WindowScrollWheelFcn = @(~,evt) camzoom(ax, 1/(1.12^double(evt.VerticalScrollCount)));

fprintf('Ready! Select Cells -> paint a piece -> SOLVE.\n');
end


%% =====================================================================
%  Mode switching
%% =====================================================================
function switch_mode(fig, mode)
C = getappdata(fig,'C');  r3d = getappdata(fig,'r3d');
setappdata(fig,'mode',mode);
h_rot=getappdata(fig,'h_rot'); h_sel=getappdata(fig,'h_sel'); h_info=getappdata(fig,'h_info');
h_rot.Value=0;  h_rot.BackgroundColor=C.btn_off;
h_sel.Value=0;  h_sel.BackgroundColor=C.btn_off;
h_info.Value=0; h_info.BackgroundColor=C.btn_off;
switch mode
    case 'rotate', r3d.Enable='on';  h_rot.Value=1;  h_rot.BackgroundColor=C.btn_on;
    case 'select', r3d.Enable='off'; h_sel.Value=1;  h_sel.BackgroundColor=[0.10 0.55 0.65];
    case 'info',   r3d.Enable='off'; h_info.Value=1; h_info.BackgroundColor=[0.70 0.42 0.00];
end
% Layer isolation only makes sense while painting; restore full cube otherwise.
if ~strcmp(mode,'select')
    h_layer = getappdata(fig,'h_layer');
    if isvalid(h_layer) && h_layer.Value ~= 1
        h_layer.Value = 1; set_layer(fig, 1);
    end
end
end

function key_handler(key, fig)
switch lower(key)
    case 'r', switch_mode(fig,'rotate');
    case 's', switch_mode(fig,'select');
    case 'i', switch_mode(fig,'info');
    case 'escape'
        return_piece(fig);
        set(getappdata(fig,'h_panel'),'Visible','off');
end
end


%% =====================================================================
%  Draw one unit cube — returns its 6 patch handles
%% =====================================================================
function handles = draw_cube(ax, x, y, z, color, edge_color, meta, fig)
V = [x y z; x+1 y z; x+1 y+1 z; x y+1 z; ...
     x y z+1; x+1 y z+1; x+1 y+1 z+1; x y+1 z+1];
F = [1 2 3 4; 5 6 7 8; 1 2 6 5; 4 3 7 8; 1 4 8 5; 2 3 7 6];
meta.base_verts = V;
handles = gobjects(1,6);
for f = 1:6
    p = patch('Vertices',V,'Faces',F(f,:),'FaceColor',color, ...
              'EdgeColor',edge_color,'LineWidth',0.7, ...
              'FaceLighting','gouraud','Parent',ax);
    p.UserData = meta;
    p.ButtonDownFcn = @(src,~) face_clicked(src,fig);
    handles(f) = p;
end
end


%% =====================================================================
%  Face-click dispatcher
%% =====================================================================
function face_clicked(src, fig)
ud = src.UserData;
if ~isstruct(ud), return; end
switch getappdata(fig,'mode')
    case 'select', toggle_cell(fig, ud.lin1);
    case 'info',   info_click(fig, ud);
end
end

function toggle_cell(fig, lin1)
sel = getappdata(fig,'selection');
sel(lin1) = ~sel(lin1);
setappdata(fig,'selection',sel);
recolor_cell(fig, lin1);
n = nnz(sel);
set_status(fig, sprintf('Painted %d cell(s). Need 4 (tetracube) or 5 (pentacube), then SOLVE.', n));
end

function recolor_cell(fig, lin1)
C   = getappdata(fig,'C');
sel = getappdata(fig,'selection');
cp  = getappdata(fig,'cellpid');
pc  = getappdata(fig,'piece_colors');
cubes = getappdata(fig,'cube_patches'); cubes = cubes{1};
if sel(lin1)
    col = C.sel; ecol = C.edge_sel; ew = 1.8;
elseif cp(lin1) > 0
    col = pc(cp(lin1),:); ecol = C.edge; ew = 0.7;
else
    col = C.grey; ecol = C.edge; ew = 0.7;
end
for h = cubes{lin1}
    if isvalid(h), h.FaceColor = col; h.EdgeColor = ecol; h.LineWidth = ew; end
end
end

function recolor_all(fig)
for lin1 = 1:64, recolor_cell(fig, lin1); end
end


%% =====================================================================
%  Strand info for one cell
%% =====================================================================
function show_strands(fig, ud)
strand_db = getappdata(fig,'strand_db');
cp        = getappdata(fig,'cellpid');
names     = getappdata(fig,'piece_names');
if cp(ud.lin1) > 0, pname = strtrim(names{cp(ud.lin1)}); else, pname = 'Unassigned (grey)'; end
dx = ud.ix+1; dy = ud.iy+1; dz = ud.iz+1;
k  = dx + 5*dy + 25*dz;
lines = make_info_lines(dx,dy,dz,k,pname,strand_db);
h_panel=getappdata(fig,'h_panel'); h_title=getappdata(fig,'h_title'); h_list=getappdata(fig,'h_list');
h_title.String = lines{1};
h_list.String  = lines(2:end);
h_list.Value   = 1;
h_panel.Visible= 'on';
end


%% =====================================================================
%  Info-mode click: pop the whole piece out, then show cell strands
%% =====================================================================
function info_click(fig, ud)
cp  = getappdata(fig,'cellpid');
pid = cp(ud.lin1);
if pid == 0
    show_strands(fig, ud);   % nothing solved here yet — just show strands
    return;
end
active = getappdata(fig,'active_piece');
if active == pid
    show_strands(fig, ud);   % already popped — show this cell's strands
    return;
end
if active ~= 0
    animate_piece(fig, active, getappdata(fig,'pop_dist'), 0, getappdata(fig,'snap_frames'));
end
animate_piece(fig, pid, 0, getappdata(fig,'pop_dist'), getappdata(fig,'pop_frames'));
setappdata(fig,'active_piece', pid);
show_strands(fig, ud);
end

function return_piece(fig)
active = getappdata(fig,'active_piece');
if active ~= 0
    animate_piece(fig, active, getappdata(fig,'pop_dist'), 0, getappdata(fig,'snap_frames'));
    setappdata(fig,'active_piece', 0);
end
end

% Patches belonging to a piece, and that piece's outward explosion direction.
function patches = piece_patches(fig, pid)
cp = getappdata(fig,'cellpid');
cubes = getappdata(fig,'cube_patches'); cubes = cubes{1};
patches = [];
for c = find(cp==pid), patches = [patches, cubes{c}]; end %#ok<AGROW>
end

function d = piece_dir(fig, pid)
cp = getappdata(fig,'cellpid');
cells = find(cp==pid) - 1;
ix = mod(cells,4); iy = mod(floor(cells/4),4); iz = floor(cells/16);
ctr = mean([ix(:)+1.5, iy(:)+1.5, iz(:)+1.5], 1);   % DNA-space centroid
d = ctr - [3 3 3];
nrm = norm(d);
if nrm < 0.1, d = [0 0 1]; nrm = 1; end
d = d / nrm;
end

function animate_piece(fig, pid, from_dist, to_dist, n)
patches = piece_patches(fig, pid);
d = piece_dir(fig, pid);
for f = 1:n
    t = f/n; t = t^2*(3-2*t);                       % ease in-out
    off = (from_dist + (to_dist-from_dist)*t) * d;
    for p = patches
        if isvalid(p), p.Vertices = p.UserData.base_verts + off; end
    end
    drawnow limitrate;
end
end

% Snap every cube back to its home position and clear the popped state.
function reset_positions(fig)
cubes = getappdata(fig,'cube_patches'); cubes = cubes{1};
for lin1 = 1:64
    for p = cubes{lin1}
        if isvalid(p), p.Vertices = p.UserData.base_verts; end
    end
end
setappdata(fig,'active_piece', 0);
end


%% =====================================================================
%  Layer isolation — show one z-slab so interior cells become clickable
%% =====================================================================
function set_layer(fig, val)
% val: 1 = all layers; 2..5 = show only z = val-2
cubes = getappdata(fig,'cube_patches'); cubes = cubes{1};
for lin1 = 1:64
    iz  = floor((lin1-1)/16);
    vis = (val==1) || (iz == val-2);
    for p = cubes{lin1}
        if isvalid(p), p.Visible = onoff(vis); end
    end
end
if val==1, set_status(fig,'Showing all layers.');
else,      set_status(fig, sprintf('Isolated layer Z=%d — interior cells are now clickable.', val-2));
end
end

function s = onoff(b)
if b, s = 'on'; else, s = 'off'; end
end


%% =====================================================================
%  SOLVE — pin painted piece, fill the rest
%% =====================================================================
function do_solve(fig)
sel = getappdata(fig,'selection');
cand_pid  = getappdata(fig,'cand_pid');
cand_mask = getappdata(fig,'cand_mask');
cand_lin  = getappdata(fig,'cand_lin');
piece_keys = getappdata(fig,'piece_keys');
cap = getappdata(fig,'sol_cap');

occ0 = uint64(0); used0 = false(1,13); cellpid0 = zeros(1,64);
pin_name = '';

if any(sel)
    lin = find(sel);
    n = numel(lin);
    if n~=4 && n~=5
        set_status(fig, sprintf('Selected %d cells — a Bedlam piece is 4 or 5 cells. Adjust and retry.', n));
        return;
    end
    lin0 = lin - 1;
    coords = [mod(lin0,4)', mod(floor(lin0/4),4)', floor(lin0/16)'];
    cc = coords - min(coords,[],1);
    key = mat2str(sortrows(round(cc)));
    pid = 0;
    for p = 1:13
        if isKey(piece_keys{p}, key), pid = p; break; end
    end
    if pid == 0
        set_status(fig,'Those cells don''t form a valid Bedlam piece (wrong shape). Adjust and retry.');
        return;
    end
    for ci = lin, occ0 = bitset(occ0, ci); end
    used0(pid)=true; cellpid0(lin)=pid;
    names = getappdata(fig,'piece_names');
    pin_name = strtrim(names{pid});
end

set_status(fig,'Solving...'); drawnow;
sols = exact_cover(occ0, used0, cellpid0, cand_pid, cand_mask, cand_lin, cap);

if isempty(sols)
    set_status(fig,'No solution exists with that piece placement.');
    return;
end
reset_positions(fig);                        % undo any popped piece
h_layer = getappdata(fig,'h_layer');
if isvalid(h_layer), h_layer.Value = 1; end
set_layer(fig, 1);                           % show the full cube
setappdata(fig,'cellpid', sols{1});
setappdata(fig,'selection', false(1,64));   % clear paint highlight
recolor_all(fig);
if isempty(pin_name), pintxt = 'no pin'; else, pintxt = ['pinned ' pin_name]; end
set_status(fig, sprintf('Solved.  (%s)', pintxt));
end

function do_clear(fig)
reset_positions(fig);
setappdata(fig,'selection', false(1,64));
setappdata(fig,'cellpid',  zeros(1,64));
h_layer = getappdata(fig,'h_layer');
if isvalid(h_layer), h_layer.Value = 1; end
set_layer(fig, 1);
recolor_all(fig);
set_status(fig,'Cleared. Paint a piece, then press SOLVE.');
end

function set_status(fig, str)
h = getappdata(fig,'h_status'); if isvalid(h), h.String = ['  ' str]; end
end


%% =====================================================================
%  Exact-cover solver (fill the lowest empty cell; pinned piece pre-set)
%% =====================================================================
function sols = exact_cover(occ0, used0, cellpid0, cand_pid, cand_mask, cand_lin, cap)
% occ0 is a uint64 bitmask (bit c set => cell c occupied). Shared state is
% mutated in place and undone on backtrack — no per-node array copies.
sols    = {};
occ     = occ0;
used    = used0;
cellpid = cellpid0;
recurse();

    function recurse()
        if numel(sols) >= cap, return; end
        c = find(bitget(occ, 1:64) == 0, 1);   % lowest empty cell
        if isempty(c)
            sols{end+1} = cellpid; %#ok<AGROW>
            return;
        end
        pids  = cand_pid{c};
        masks = cand_mask{c};
        lins  = cand_lin{c};
        for i = 1:numel(pids)
            pid = pids(i);
            if used(pid), continue; end
            m = masks(i);
            if bitand(occ, m), continue; end   % nonzero => overlap
            occ        = bitor(occ, m);
            used(pid)  = true;
            L          = lins{i};
            cellpid(L) = pid;
            recurse();
            occ        = bitxor(occ, m);        % undo (bits were 0 before)
            used(pid)  = false;
            cellpid(L) = 0;
            if numel(sols) >= cap, return; end
        end
    end
end


%% =====================================================================
%  Build all legal placements, indexed by the cells they cover
%% =====================================================================
function [cand_pid, cand_mask, cand_lin, piece_keys] = build_placements(shapes)
R = rot24();
cand_pid  = cell(1,64);   % cand_pid{c}  = 1xK piece ids of placements covering cell c
cand_mask = cell(1,64);   % cand_mask{c} = 1xK uint64 occupancy masks
cand_lin  = cell(1,64);   % cand_lin{c}  = 1xK cell of covered-cell index vectors
for i = 1:64, cand_pid{i} = []; cand_mask{i} = uint64([]); cand_lin{i} = {}; end
piece_keys = cell(13,1);

for p = 1:13
    ors  = orientations(shapes{p}, R);
    keys = containers.Map('KeyType','char','ValueType','logical');
    for j = 1:numel(ors)
        cells = ors{j};                       % normalized, min = 0
        keys(mat2str(cells)) = true;
        mx = max(cells,[],1);
        for tz = 0:(3-mx(3))
            for ty = 0:(3-mx(2))
                for tx = 0:(3-mx(1))
                    tc  = cells + [tx ty tz];
                    lin = sort(tc(:,1) + 4*tc(:,2) + 16*tc(:,3) + 1)';
                    m = uint64(0);
                    for ci = lin, m = bitset(m, ci); end
                    for ci = lin
                        cand_pid{ci}(end+1)  = p;
                        cand_mask{ci}(end+1) = m;
                        cand_lin{ci}{end+1}  = lin;
                    end
                end
            end
        end
    end
    piece_keys{p} = keys;
end
end

% Unique normalized orientations of a polycube under the 24 rotations.
function ors = orientations(shape, R)
seen = containers.Map('KeyType','char','ValueType','logical');
ors = {};
for i = 1:numel(R)
    c = shape * R{i}';
    c = c - min(c,[],1);
    c = sortrows(round(c));
    key = mat2str(c);
    if ~isKey(seen,key)
        seen(key) = true;
        ors{end+1} = c; %#ok<AGROW>
    end
end
end

% 24 proper rotation matrices of the cube (signed permutation, det = +1).
function R = rot24()
P = perms(1:3);
R = {};
for i = 1:size(P,1)
    for s = 0:7
        sgn = 1 - 2*[bitget(s,1) bitget(s,2) bitget(s,3)];
        M = zeros(3);
        for r = 1:3, M(r,P(i,r)) = sgn(r); end
        if abs(det(M)-1) < 1e-9
            R{end+1} = M; %#ok<AGROW>
        end
    end
end
end


%% =====================================================================
%  Piece table + shape derivation (same arrangement as fourbyfourbyfour)
%% =====================================================================
function [piece_colors, piece_names, data] = piece_table()
piece_names = { ...
    'Brown  (block0)','Red    (block1)','Green  (block2)', ...
    'DkGreen(block3)','Purple (block4)','Gray   (block5)', ...
    'Orange (block6)','White  (block7)','LtGray (block8)', ...
    'LtBlue (block9)','Yellow (blockA)','Blue   (blockB)', ...
    'Pink   (blockC) [tetracube]'};

piece_colors = [ ...
    0.60 0.40 0.20; 1.00 0.20 0.20; 0.20 0.85 0.20; 0.00 0.55 0.00; ...
    0.80 0.40 1.00; 0.58 0.58 0.58; 1.00 0.60 0.00; 0.87 0.87 0.87; ...
    0.72 0.72 0.72; 0.40 0.80 1.00; 1.00 1.00 0.00; 0.15 0.50 1.00; ...
    1.00 0.65 0.80];

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
    0 3 3 11;  1 3 3  7;  2 3 3  7;  3 3 3  7];
end

function shapes = derive_shapes(data)
shapes = cell(13,1);
for p = 1:13
    cells = data(data(:,4)==p, 1:3);
    shapes{p} = cells - min(cells,[],1);   % normalize to origin
end
end


%% =====================================================================
%  Build info lines for one cell  (DNA coords 1..4)
%% =====================================================================
function lines = make_info_lines(dx,dy,dz,k,pname,strand_db)
face_note = {'','','','','','',''};
if dx==1, face_note{4}='  [X- face SE]'; end
if dy==1, face_note{5}='  [Y- face SE]'; end
if dz==1, face_note{3}='  [Z- bottom SE]'; end

lines = { ...
    sprintf('Piece: %s', pname), ...
    sprintf('Position:  x=%d   y=%d   z=%d   (unit k=%d)', dx,dy,dz,k), ...
    '-----------------------------------------', ...
    'DNA Strands  (7 per tensegrity triangle):'};

for off = 1:7
    sn = int32(7*k + off);
    if isKey(strand_db, sn)
        e = strand_db(sn); sname = e{1}; sseq = e{2};
        if numel(sseq) > 42, sdisp = [sseq(1:42) '...']; else, sdisp = sseq; end
        lines{end+1} = sprintf('[%d] %s%s', off, sname, face_note{off}); %#ok<AGROW>
        lines{end+1} = sprintf('    %s', sdisp);                         %#ok<AGROW>
        lines{end+1} = '';                                                %#ok<AGROW>
    else
        lines{end+1} = sprintf('[%d] Strand%d  (not found)', off, sn);   %#ok<AGROW>
        lines{end+1} = '';                                                %#ok<AGROW>
    end
end
end


%% =====================================================================
%  Strand loading (single sheet: col1 = sequence, col2 = "Strand N")
%% =====================================================================
function db = load_strands(excel_path)
db = containers.Map('KeyType','int32','ValueType','any');
T = safe_readtable(excel_path, 1);
for r = 1:height(T)
    seq = to_str(T{r,1});  nm = to_str(T{r,2});
    if isempty(nm)||isempty(seq), continue; end
    n = strand_num(nm);
    if ~isnan(n), db(int32(n)) = {nm,seq}; end
end
fprintf('  Loaded: %d strands.\n', db.Count);
end

function T = safe_readtable(path, sheet)
try
    opts = detectImportOptions(path,'Sheet',sheet);
    opts.VariableNamesRange = '';
    opts.DataRange = 'A1';
    opts = setvartype(opts, opts.VariableNames, 'char');
    T = readtable(path, opts); return;
catch
end
try
    T = readtable(path,'Sheet',sheet,'ReadVariableNames',false); return;
catch
end
try
    [~,~,raw] = xlsread(path, sheet);
    if isempty(raw), T = table(); return; end
    for i = 1:numel(raw)
        if isnumeric(raw{i}) && isscalar(raw{i}) && isnan(raw{i})
            raw{i} = '';
        elseif isnumeric(raw{i})
            raw{i} = num2str(raw{i});
        end
    end
    T = cell2table(raw); return;
catch e
    warning('safe_readtable: %s', e.message);
    T = table();
end
end

function s = to_str(v)
if iscell(v), v = v{1}; end
if ischar(v),       s = strtrim(v);
elseif isstring(v), s = strtrim(char(v));
else,               s = '';
end
end

function n = strand_num(name)
tok = regexp(name,'(?i)strand\s*(\d+)','tokens','once');
if isempty(tok), n = NaN; else, n = str2double(tok{1}); end
end
