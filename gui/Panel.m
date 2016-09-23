classdef Panel < Container
    
    properties(SetAccess = protected)
        panelHandle;
    end
    
    methods
        function this = Panel(parent)
            if(~isa(parent, 'Figure') && ~isa(parent, 'Panel'))
                exception = MException('Panel:invalidArgument', '''parent'' must be a valid instance of Figure or Panel');
                throw(exception);
            end
            
            this.parent = parent;
            
            addlistener(parent, 'ButtonMotion', @(src, evnt) this.buttonMotion());
            addlistener(parent, 'ButtonUp', @(src, evnt) this.buttonUp());
            
            this.createPanel();
        end
    end
    
    methods(Access = protected)
        function createPanel(this)
            this.panelHandle = uipanel(this.parent.handle);
            
            set(this.panelHandle, 'ButtonDownFcn', @(src, evnt) this.buttonDown());
        end
    end
end