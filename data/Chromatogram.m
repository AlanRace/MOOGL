classdef Chromatogram < SpectralData
    methods
        function obj = Chromatogram(time, intensities)
            obj = obj@SpectralData(time, intensities);
        end
    end
end