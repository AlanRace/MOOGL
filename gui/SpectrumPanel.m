classdef SpectrumPanel < Panel
    
    properties (SetAccess = protected)        
        spectrumDisplay;
    end
    
    methods
        function this = SpectrumPanel(parent)
            this = this@Panel(parent);
        end
    end
    
    methods(Access = protected)       
        function createPanel(this)
            createPanel@Panel(this);
            
            this.spectrumDisplay = SpectrumDisplay(this, SpectralData(1:100, rand(1,100)));
        end
    end
end