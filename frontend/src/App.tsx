import { BrowserRouter, Routes, Route } from 'react-router-dom';
import HomePage from './pages/public/HomePage';
import LoginPage from './pages/public/LoginPage';
import AdminDashboard from './pages/admin/AdminDashboard';
import CreateProduct from './pages/admin/CreateProduct';
import CreateReseller from './pages/admin/CreateReseller';
import EditProduct from './pages/admin/EditProduct';
import EditReseller from './pages/admin/EditReseller';
import ProductDetail from './pages/public/ProductDetail';
import ClientDashboard from './pages/reseller/ClientDashboard';

function App() {
    return (
        <BrowserRouter>
            <Routes>
                <Route path="/" element={<HomePage />} />
                <Route path="/products/:id" element={<ProductDetail />} />
                <Route path="/auth/login/admin" element={<LoginPage type="admin" />} />
                <Route path="/auth/login/reseller" element={<LoginPage type="reseller" />} />
                <Route path="/admin/dashboard" element={<AdminDashboard />} />
                <Route path="/admin/products/create" element={<CreateProduct />} />
                <Route path="/admin/products/edit/:id" element={<EditProduct />} />
                <Route path="/admin/resellers/create" element={<CreateReseller />} />
                <Route path="/admin/resellers/edit/:id" element={<EditReseller />} />
                <Route path="/client/dashboard" element={<ClientDashboard />} />
            </Routes>
        </BrowserRouter>
    );
}

export default App;


