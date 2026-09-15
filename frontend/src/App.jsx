import { BrowserRouter, Routes, Route } from "react-router-dom";

import Home from "./pages/Home";
import PHCLogin from "./pages/PHCLogin";
import PHCHome from "./pages/PHCHome";
import PreviousPatients from "./pages/PreviousPatients";
import Screening from "./pages/Screening";
import Result from "./pages/Result";
import Report from "./pages/Report";

import Doctorlogin from "./pages/Doctorlogin";
import Doctorhome from "./pages/Doctorhome";
import DoctorCase from "./pages/DoctorCase";
import DoctorInfo from "./pages/DoctorInfo";

function App() {
  return (
    <BrowserRouter>
      <Routes>

        {/* Home */}
        <Route path="/" element={<Home />} />

        {/* PHC Worker */}
        <Route path="/phc-login" element={<PHCLogin />} />
        <Route path="/phc-home" element={<PHCHome />} />
        <Route path="/previous-patients" element={<PreviousPatients />} />
        <Route path="/screening" element={<Screening />} />
        <Route path="/result" element={<Result />} />
        <Route path="/report" element={<Report />} />

        {/* Doctor */}
        <Route path="/doctor-login" element={<Doctorlogin />} />
        <Route path="/doctor-home" element={<Doctorhome />} />
        <Route path="/doctor-case" element={<DoctorCase />} />

        {/* Doctor Information */}
        <Route path="/doctor-info" element={<DoctorInfo />} />

      </Routes>
    </BrowserRouter>
  );
}

export default App;
