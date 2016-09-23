classdef (Abstract) Container < handle
    
    properties (SetAccess = protected)
        % MATLAB figure handle
        handle = [];
        
        parent;
    end
    
    events
        ButtonDown;
        ButtonUp;
        ButtonMotion;
    end
    
    methods
        function figure = getParentFigure(this)
            if(isa(this, 'Figure'))
                figure = this;
            else
                figure = this.parent.getParentFigure();
            end
        end
    end
    
    methods (Access = protected)
        function buttonDown(this)
            notify(this, 'ButtonDown');
        end
        
        function buttonMotion(this)
            notify(this, 'ButtonMotion');
        end
        
        function buttonUp(this)
            notify(this, 'ButtonUp');
        end
    end
    
    methods (Static)
        function position = getPositionInPixels(object) 
            % getPositionInPixels  Get the position of the object within 
            % the figure in pixels.
            %
            %    position = getPositionInPixels(object) 
            
            
            oldUnits = get(object, 'Units');
            set(object, 'Units', 'pixels');
            
            position = get(object, 'Position');
            set(object, 'Units', oldUnits);
        end
        
        function setObjectPositionInPixels(object, newPosition)
            % setObjectPositionInPixels Set the position of object in 
            % pixels.
            %
            %   setObjectPositionInPixels(object, newPosition) 
            
            % Ensure that we're setting the size to a valid one
            if(newPosition(3) > 0 && newPosition(4) > 0)
                oldUnits = get(object, 'Units');
                set(object, 'Units', 'pixels');
                set(object, 'Position', newPosition);
                set(object, 'Units', oldUnits);
            end
        end
    end
end