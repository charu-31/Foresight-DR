import os

try:
    import matlab.engine
    HAS_MATLAB = True
except ImportError:
    HAS_MATLAB = False
    print("\n[WARNING] matlab.engine package not found. Running in MOCK BACKEND mode for UI testing.\n")


class MATLABBridge:
    def __init__(self):
        self.eng = None

    def start_engine(self):
        if not HAS_MATLAB:
            print("MATLAB engine disabled. Proceeding with Mock Data Server.")
            return

        print("Starting MATLAB engine...")
        try:
            self.eng = matlab.engine.start_matlab()
            matlab_dir = os.path.abspath(r"C:\Users\hp\Documents\ai model")
            self.eng.addpath(matlab_dir, nargout=0)
            self.eng.cd(matlab_dir, nargout=0)
            print("MATLAB engine connected! Using REAL ForeSight DR Analysis.")
        except Exception as e:
            print(f"Failed to initialize MATLAB engine: {e}. Falling back to Mock mode.")
            self.eng = None

    def stop_engine(self):
        if self.eng:
            self.eng.quit()
            print("MATLAB engine stopped.")

    def analyze_image(self, image_path: str):
        # 1. Real MATLAB Analysis
        if self.eng:
            res = self.eng.ForeSightDR_Backend(image_path, nargout=1)
            return {
                "drGrade": int(res["drGrade"]),
                "drClass": str(res["drClass"]),
                "confidence": round(float(res["confidence"]) * 100, 2),
                "gradCAMImage": str(res["gradCAMImage"]),
                "localizationImage": str(res["localizationImage"]),
                "lesionOverlay": str(res["lesionOverlay"]),
                "lesionCounts": {
                    "microaneurysm": int(res["lesionCounts"][0][0]),
                    "haemorrhage": int(res["lesionCounts"][1][0]),
                    "hardExudate": int(res["lesionCounts"][2][0]),
                    "softExudate": int(res["lesionCounts"][3][0]),
                }
            }

        # 2. Mock Fallback (Runs when MATLAB Engine is absent)
	# 2. MATLAB Engine unavailable
raise RuntimeError(
    "MATLAB Engine is not connected. Real screening cannot be performed.")
       
# Global singleton instance
bridge = MATLABBridge()