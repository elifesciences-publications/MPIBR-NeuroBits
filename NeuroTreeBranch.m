classdef NeuroTreeBranch < handle
    %
    % NeuroTreeBranch
    %
    % support class for WidgetNeuroTree 
    % keep properties per tree branch
    % draw methods for branch
    %
    % used by:
    %    WidgetNeuroTree
    %
    % Georgi Tushev
    % sciclist@brain.mpg.de
    % Max-Planck Institute For Brain Research
    %
    
    properties
        tag
        index
        parent
        children
        depth
        nodes
        span
        pixels
        range
    end
    
    properties (Access = private, Hidden = true)
        ui_parent
        ui_point
        ui_line
        ui_label
    end
    
    properties(Constant = true, Hidden = true)
        
        LINE_WIDTH = 4;
        ALPHALINE_ON = 0.5;
        ALPHALINE_OFF = 1;
        MARKER_SIZE = 5;
        FONT_SIZE = 10;
        DEFAULT_NODE = [0,0];
        
        BRANCH_POINT_RADIUS = 100;
        
        COLOR_TABLE = [255,0,0;...   % red
                      255,125,0;... % orange
                      255,255,0;... % yellow
                      125,255,0;... % spring green
                      0,255,0;...   % green
                      0,255,125;... % turquoise
                      0,255,255;... % cyan
                      0,125,255;... % ocean
                      0,0,255;...   % blue
                      125,0,255;... % violet
                      255,0,255;... % magenta
                      255,0,125]... % raspberry
                      ./255; 
                  
    end
    
    %%% --- constructor / destructor --- %%%
    methods
        
        function obj = NeuroTreeBranch(varargin)
            %NEUROTREEBRANCH class constructor
            
            % use parser
            parserObj = inputParser;
            
            % define inputs
            addParameter(parserObj, 'Index', [], @isIndex);
            addParameter(parserObj, 'Depth', [], @isDepth);
            addParameter(parserObj, 'Height', [], @isnumeric);
            addParameter(parserObj, 'Width', [], @isnumeric);
            addParameter(parserObj, 'Parent', [], @(x) isgraphics(x, 'Axes'));
            
            % parse varargin
            parse(parserObj, varargin{:});
            
            % set properties
            obj.index = parserObj.Results.Index;
            obj.depth = str2double(parserObj.Results.Depth);
            obj.ui_parent = parserObj.Results.Parent;
            obj.range = [parserObj.Results.Height, parserObj.Results.Width];
            
            % default values
            obj.default();
            
        end
        
        function obj = default(obj)
            %DEFAULT set properties default values
            
            obj.tag = 0;
            obj.parent = [];
            obj.children = [];
            obj.nodes = obj.DEFAULT_NODE;
            obj.span = 0;
            obj.pixels = [];
            
            % create hidden handles
            hold(obj.ui_parent, 'on');
            
            obj.ui_point = plot(obj.nodes(:,1), obj.nodes(:,2), '*',...
                                'MarkerSize', obj.MARKER_SIZE,...
                                'Color', obj.COLOR_TABLE(obj.depth + 1, :),...
                                'Parent', obj.ui_parent,...
                                'Visible', 'off');
           
            obj.ui_line = plot(obj.nodes(:,1),obj.nodes(:,2), '-',...
                                'LineWidth', obj.LINE_WIDTH,...
                                'Color', obj.COLOR_TABLE(obj.depth + 1, :),...
                                'Parent', obj.ui_parent,...
                                'Visible', 'off');
            obj.ui_line.Color(4) = obj.ALPHALINE_ON;
            
            obj.ui_label = text(obj.nodes(:,1), obj.nodes(:,2), '',...
                                'FontSize', obj.FONT_SIZE,...
                                'Parent', obj.ui_parent,...
                                'Visible', 'off');
                            
            hold(obj.ui_parent, 'off');
            
            % reorder uistack
            % points need to be on top of line to retrieve node
            uistack(obj.ui_point, 'top');
            
            % integrate current branch index in user data
            set(obj.ui_point, 'UserData', obj.index);
            set(obj.ui_line, 'UserData', obj.index);
            set(obj.ui_label, 'UserData', obj.index);
            
        end
        
        
        function obj = dispose(obj)
            %DISPOSE class destructor
            
            delete(obj.ui_point);
            delete(obj.ui_line);
            delete(obj.ui_label);
            delete(obj);
            
        end
        
    end % constructor / destructor
    
    
    %%% --- modify branches --- %%%
    methods
        
        function obj = stretch(obj, indexNode, point)
            %STRETCH extends branch without appending node
            
            % update line handler Data
            obj.ui_line.XData(indexNode) = point(1);
            obj.ui_line.YData(indexNode) = point(2);
            
        end
        
        
        function obj = extend(obj, indexNode, point)
            %EXTEND appends node to the branch
            
            % add point to nodes
            obj.nodes(indexNode, :) = point;
            
            % update point handler data
            obj.ui_point.XData(indexNode) = point(1);
            obj.ui_point.YData(indexNode) = point(2);
            set(obj.ui_point, 'Visible', 'on');
            
            % update line handler data
            obj.ui_line.XData(indexNode) = point(1);
            obj.ui_line.YData(indexNode) = point(2);
            set(obj.ui_line, 'Visible', 'on');
            
        end
        
        
        function obj = move(obj, offset)
            %MOVE update branch position with given offset
            
            % update nodes
            obj.nodes = bsxfun(@plus, obj.nodes, offset);
            
            % update line
            obj.ui_line.XData = obj.ui_line.XData + offset(1);
            obj.ui_line.YData = obj.ui_line.YData + offset(2);
            
            % update points
            obj.ui_point.XData = obj.ui_point.XData + offset(1);
            obj.ui_point.YData = obj.ui_point.YData + offset(2);
            
        end
        
        
        function obj = complete(obj, nhood)
            %COMPLETE complete branch drawing
            % calculates branch length, pixels and neighbours
            
            % close polygon if depth is root
            if obj.depth == 0
                
                % update nodes
                obj.nodes = cat(1, obj.nodes, obj.nodes(1, :));
                
                % update line
                obj.ui_line.XData = cat(2, obj.ui_line.XData, obj.ui_line.XData(1));
                obj.ui_line.YData = cat(2, obj.ui_line.YData, obj.ui_line.YData(1));
            end
            
            % measure branch length
            obj.measure();
            
            % interpolate branch nodes to pixels
            %obj.interpolate();
            
            % link relatives
            %obj.link();
            
        end
        
        
        function obj = measure(obj)
            %MEASURE find span of branch
            
            dist = sqrt(sum(diff(obj.nodes, [], 1) .^ 2, 2));
            obj.span = round(sum(dist));
            
        end
        
        function obj = interpolate(obj)
            %INTERPOLATE convert nodes to pixels
            
            % calculate cumulative pixel distance along line
            dNodes = sqrt(sum(diff(obj.nodes, [], 1).^2, 2));
            csNodes = cat(1, 0, cumsum(dNodes));
            
            % resample nodes at sub-pixel intervals
            sampleCsNodes = linspace(0, csNodes(end), ceil(csNodes(end)/0.5));
            sampleNodes = interp1(csNodes, obj.nodes, sampleCsNodes);
            sampleNodes = round(sampleNodes);
            
            % return pixel indexes
            obj.pixels = sub2ind(obj.range, sampleNodes(:,2), sampleNodes(:,1));
            
        end
        
        
        function obj = tweak(obj, indexNode, point)
            %TWEAK updates node point
            
            % update nodes
            obj.nodes(indexNode,:) = point;
            
            % update line
            obj.ui_line.XData(indexNode) = point(1);
            obj.ui_line.YData(indexNode) = point(2);
            
            % update points
            obj.ui_point.XData(indexNode) = point(1);
            obj.ui_point.YData(indexNode) = point(2);
            
        end
        
        
        function obj = remove(obj, indexNode)
            %REMOVE removes node from data arrays
            
            % update nodes
            obj.nodes(indexNode, :) = [];
            
            % update point
            obj.ui_point.XData(indexNode) = [];
            obj.ui_point.YData(indexNode) = [];
            
            % update line
            obj.ui_line.XData(indexNode) = [];
            obj.ui_line.YData(indexNode) = [];
            
        end
        
        
        function obj = select(obj)
            %SELECT highligh branch ui
            
            % remove line Alpha property
            obj.ui_line.Color(4) = obj.ALPHALINE_OFF;
            
            % double the size of marker size
            obj.ui_point.MarkerSize = 2 * obj.MARKER_SIZE;
            
        end
        
        
        function obj = deselect(obj)
            %DESELECT remove branch ui highlight
            
            % revert line Alpha value
            obj.ui_line.Color(4) = obj.ALPHALINE_ON;
            
            % revert point marker size
            obj.ui_point.MarkerSize = obj.MARKER_SIZE;
            
        end
        
        
        function value = color(obj)
            %COLOR returns current branch color
            
            value = round(255 .* obj.COLOR_TABLE(obj.depth + 1, :));
            
        end
        
    end % modify branch
end


% parser :: isIndex
%  input :: parserValue
% action :: check if parserValue is valid index
function tf = isIndex(parserValue)

    % default output
    tf = true;
    
    % check if numeric
    if ~isnumeric(parserValue)
        tf = false;
    end
    
    % check if whole number
    if rem(parserValue, 1) ~= 0
        tf = false;
    end
    
end

% parser :: isDepth
%  input :: parserValue
% action :: check if parserValue is valid depth
function tf = isDepth(parserValue)

    % default output
    tf = true;
    
    % check if char
    if ~ischar(parserValue)
        tf = false;
    end
    
    % check if in range
    if (parserValue < '0') || (parserValue > '9')
        tf = false;
    end
    
end
