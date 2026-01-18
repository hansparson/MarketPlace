import { useEffect, useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import {
    ChartBarIcon,
    UserGroupIcon,
    ShoppingBagIcon,
    PlusCircleIcon,
    ArrowRightOnRectangleIcon,
    PhotoIcon,
    HomeIcon,
    XMarkIcon
} from '@heroicons/react/24/outline';
import client from '../api/client';
import { getImageUrl } from '../utils/image';
import { formatRelativeTime } from '../utils/date';

const AdminDashboard = () => {
    const navigate = useNavigate();
    const [stats, setStats] = useState<any>(null);
    const [products, setProducts] = useState<any[]>([]);
    const [resellers, setResellers] = useState<any[]>([]);
    const [activeTab, setActiveTab] = useState<'overview' | 'products' | 'resellers'>('overview');
    const [loading, setLoading] = useState(true);

    // Pagination
    const [currentPage, setCurrentPage] = useState(1);
    const [totalPages, setTotalPages] = useState(1);
    const [limit] = useState(5);

    // Sold Logic
    const [isSoldModalOpen, setIsSoldModalOpen] = useState(false);
    const [selectedProductForSold, setSelectedProductForSold] = useState<any>(null);
    const [productLeads, setProductLeads] = useState<any[]>([]);
    const [selectedLeadId, setSelectedLeadId] = useState('');
    const [isFinalizingSold, setIsFinalizingSold] = useState(false);
    const [unitsSold, setUnitsSold] = useState(1); // NEW: Track units sold

    useEffect(() => {
        const token = localStorage.getItem('token');
        const role = localStorage.getItem('role');

        if (!token || role !== 'SUPER_ADMIN' && role !== 'ADMIN') {
            navigate('/auth/login/admin');
            return;
        }

        loadDashboard();

        // Real-time polling for stats (every 5 seconds)
        const interval = setInterval(() => {
            loadDashboard();
        }, 5000);

        return () => clearInterval(interval);
    }, [navigate]);

    useEffect(() => {
        if (activeTab === 'products') {
            loadProducts(currentPage);
        } else if (activeTab === 'resellers') {
            loadResellers();
        }
    }, [activeTab, currentPage]);

    const loadDashboard = async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await client.get('/admin/dashboard', {
                headers: { Authorization: `Bearer ${token}` }
            });
            if (res.data && res.data.message_data) {
                setStats(res.data.message_data);
            }
        } catch (err) {
            console.error('Failed to load dashboard', err);
        } finally {
            setLoading(false);
        }
    };

    const loadProducts = async (page = 1) => {
        try {
            const token = localStorage.getItem('token');
            const res = await client.get(`/admin/products?page=${page}&limit=${limit}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            if (res.data && res.data.message_data) {
                if (res.data.message_data.items) {
                    setProducts(res.data.message_data.items);
                    setTotalPages(res.data.message_data.pagination.total_pages);
                } else if (Array.isArray(res.data.message_data)) {
                    setProducts(res.data.message_data);
                }
            }
        } catch (err) {
            console.error('Failed to load products', err);
        }
    };

    const loadResellers = async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await client.get('/admin/resellers', {
                headers: { Authorization: `Bearer ${token}` }
            });
            if (res.data && res.data.message_data) {
                setResellers(res.data.message_data);
            }
        } catch (err) {
            console.error('Failed to load resellers', err);
        }
    };

    const handleLogout = () => {
        localStorage.removeItem('token');
        localStorage.removeItem('role');
        navigate('/');
    };

    const handleOpenSoldModal = async (product: any) => {
        setSelectedProductForSold(product);
        setIsSoldModalOpen(true);
        setProductLeads([]);
        setSelectedLeadId('');
        setUnitsSold(1); // Reset to 1 unit

        try {
            const token = localStorage.getItem('token');
            const res = await client.get(`/admin/products/${product.id}/leads`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            if (res.data && res.data.message_data) {
                setProductLeads(res.data.message_data);
            }
        } catch (err) {
            console.error('Failed to load product leads', err);
        }
    };

    const handleConfirmSold = async () => {
        if (!selectedProductForSold) return;

        // Validation
        if (unitsSold <= 0) {
            alert('Units sold must be greater than 0');
            return;
        }

        if (unitsSold > selectedProductForSold.stock) {
            alert(`Not enough stock. Available: ${selectedProductForSold.stock}, Requested: ${unitsSold}`);
            return;
        }

        setIsFinalizingSold(true);
        try {
            const token = localStorage.getItem('token');
            const res = await client.post(`/admin/products/${selectedProductForSold.id}/sold`, {
                units_sold: unitsSold, // Send units sold
                lead_id: selectedLeadId
            }, {
                headers: { Authorization: `Bearer ${token}` }
            });

            const message = res.data?.message_data?.message || 'Product sold successfully!';
            alert(message);
            setIsSoldModalOpen(false);
            loadDashboard();
            if (activeTab === 'products') loadProducts(currentPage);
        } catch (err: any) {
            console.error('Failed to mark as sold', err);
            const errorMsg = err.response?.data?.error || err.response?.data?.message || 'Failed to mark as sold';
            alert(errorMsg);
        } finally {
            setIsFinalizingSold(false);
        }
    };

    // Use centralized getImageUrl from utils/image

    const formatPrice = (price: number) => {
        return new Intl.NumberFormat('id-ID', {
            style: 'currency',
            currency: 'IDR',
            minimumFractionDigits: 0
        }).format(price);
    };

    const statCards = [
        {
            title: 'Total Products',
            value: stats?.total_products || 0,
            icon: ShoppingBagIcon,
            color: 'bg-gradient-to-br from-blue-500 to-blue-600',
            iconBg: 'bg-blue-100',
            iconColor: 'text-blue-600'
        },
        {
            title: 'Total Resellers',
            value: stats?.total_resellers || 0,
            icon: UserGroupIcon,
            color: 'bg-gradient-to-br from-green-500 to-green-600',
            iconBg: 'bg-green-100',
            iconColor: 'text-green-600'
        },
        {
            title: 'Total Clicks',
            value: stats?.total_clicks || 0,
            icon: ChartBarIcon,
            color: 'bg-gradient-to-br from-purple-500 to-purple-600',
            iconBg: 'bg-purple-100',
            iconColor: 'text-purple-600'
        },
        {
            title: 'Verifications',
            value: stats?.total_verifications || 0,
            icon: ChartBarIcon,
            color: 'bg-gradient-to-br from-orange-500 to-orange-600',
            iconBg: 'bg-orange-100',
            iconColor: 'text-orange-600'
        },
    ];

    return (
        <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
            {/* Header */}
            <header className="bg-white shadow-sm border-b border-gray-200 sticky top-0 z-30">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-3 sm:py-4">
                    <div className="flex flex-col sm:flex-row justify-between items-center gap-4">
                        <button
                            onClick={() => navigate('/')}
                            className="flex items-center gap-3 hover:opacity-80 transition-opacity w-full sm:w-auto"
                        >
                            <img src="/logo.jpg" alt="Gostar Mart" className="h-8 sm:h-10 w-auto object-contain" />
                            <div className="text-left">
                                <h1 className="text-xl sm:text-2xl font-bold text-gray-900 leading-tight">Admin Dashboard</h1>
                                <p className="text-[10px] sm:text-sm text-gray-500">Gostar Mart Management</p>
                            </div>
                        </button>
                        <div className="flex items-center gap-2 sm:gap-3 w-full sm:w-auto justify-end">
                            <button
                                onClick={() => navigate('/')}
                                className="flex-1 sm:flex-none flex items-center justify-center gap-2 px-3 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors font-medium text-sm"
                            >
                                <HomeIcon className="w-4 h-4" />
                                <span className="hidden sm:inline">Back to Home</span>
                                <span className="sm:hidden text-xs">Home</span>
                            </button>
                            <button
                                onClick={handleLogout}
                                className="flex-1 sm:flex-none flex items-center justify-center gap-2 px-3 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors font-medium text-sm"
                            >
                                <ArrowRightOnRectangleIcon className="w-4 h-4" />
                                <span className="hidden sm:inline">Logout</span>
                                <span className="sm:hidden text-xs">Logout</span>
                            </button>
                        </div>
                    </div>
                </div>
            </header>

            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                {/* Stats Grid */}
                {loading ? (
                    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 mb-8">
                        {[1, 2, 3, 4].map((i) => (
                            <div key={i} className="bg-white rounded-xl p-6 shadow-sm animate-pulse">
                                <div className="h-20 bg-gray-200 rounded"></div>
                            </div>
                        ))}
                    </div>
                ) : (
                    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 mb-8">
                        {statCards.map((stat, index) => (
                            <div
                                key={index}
                                className="bg-white rounded-2xl p-4 sm:p-6 shadow-sm hover:shadow-md transition-shadow border border-gray-100 flex flex-col justify-between"
                            >
                                <div className="flex items-center justify-between mb-3">
                                    <div className={`p-2.5 rounded-xl ${stat.iconBg}`}>
                                        <stat.icon className={`w-5 h-5 sm:w-6 sm:h-6 ${stat.iconColor}`} />
                                    </div>
                                </div>
                                <div>
                                    <h3 className="text-gray-400 text-[10px] sm:text-xs font-bold mb-1 uppercase tracking-widest">{stat.title}</h3>
                                    <p className="text-xl sm:text-3xl font-black text-gray-900">{stat.value.toLocaleString()}</p>
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {/* Tabs */}
                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                    <div className="border-b border-gray-100 overflow-x-auto scrollbar-hide whitespace-nowrap">
                        <nav className="flex p-1">
                            {[
                                { key: 'overview', label: 'Overview', icon: ChartBarIcon },
                                { key: 'products', label: 'Products', icon: ShoppingBagIcon },
                                { key: 'resellers', label: 'Resellers', icon: UserGroupIcon },
                            ].map((tab) => (
                                <button
                                    key={tab.key}
                                    onClick={() => setActiveTab(tab.key as any)}
                                    className={`flex items-center gap-2 px-6 py-3.5 text-xs sm:text-sm font-black rounded-xl transition-all ${activeTab === tab.key
                                        ? 'bg-blue-50 text-blue-600 shadow-sm'
                                        : 'text-gray-500 hover:text-gray-900 hover:bg-gray-50'
                                        }`}
                                >
                                    <tab.icon className="w-4 h-4 sm:w-5 sm:h-5" />
                                    {tab.label}
                                </button>
                            ))}
                        </nav>
                    </div>

                    <div className="p-6">
                        {activeTab === 'overview' && (
                            <div className="space-y-6">
                                <h3 className="text-lg font-bold text-gray-900">Recent Activity Stream (Real-time)</h3>
                                {stats?.recent_activities && stats.recent_activities.length > 0 ? (
                                    <>
                                        <div className="hidden md:block bg-white rounded-xl border border-gray-200 overflow-hidden">
                                            <table className="min-w-full divide-y divide-gray-200">
                                                <thead className="bg-gray-50">
                                                    <tr>
                                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Time</th>
                                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Lead</th>
                                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Product</th>
                                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Reseller</th>
                                                        <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
                                                    </tr>
                                                </thead>
                                                <tbody className="bg-white divide-y divide-gray-200">
                                                    {stats.recent_activities.map((act: any, idx: number) => (
                                                        <tr key={idx} className="hover:bg-blue-50/50 transition-colors">
                                                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                                                {new Date(act.created_at).toLocaleString('id-ID')}
                                                            </td>
                                                            <td className="px-6 py-4 whitespace-nowrap">
                                                                <div className="text-sm font-medium text-gray-900">{act.visitor_name}</div>
                                                                <div className="text-sm text-gray-500">{act.visitor_phone}</div>
                                                            </td>
                                                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                                                {act.product_title}
                                                            </td>
                                                            <td className="px-6 py-4 whitespace-nowrap">
                                                                <div className="text-sm font-medium text-blue-600">{act.reseller_name}</div>
                                                                <div className="text-xs text-gray-500">{act.referral_code}</div>
                                                            </td>
                                                            <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                                                <a href={`/products/${act.product_id}`} target="_blank" rel="noreferrer" className="text-blue-600 hover:text-blue-900">
                                                                    View
                                                                </a>
                                                            </td>
                                                        </tr>
                                                    ))}
                                                </tbody>
                                            </table>
                                        </div>
                                        {/* Mobile View Activity */}
                                        <div className="md:hidden space-y-4">
                                            {stats.recent_activities.map((act: any, idx: number) => (
                                                <div key={idx} className="bg-white p-4 rounded-xl border border-gray-200 space-y-3">
                                                    <div className="flex justify-between items-start">
                                                        <span className="text-[10px] font-bold text-gray-400 border border-gray-100 px-2 py-0.5 rounded uppercase">
                                                            {new Date(act.created_at).toLocaleTimeString('id-ID')}
                                                        </span>
                                                        <a href={`/products/${act.product_id}`} target="_blank" rel="noreferrer" className="text-xs font-bold text-blue-600">
                                                            View Product
                                                        </a>
                                                    </div>
                                                    <div>
                                                        <p className="text-sm font-bold text-gray-900">{act.visitor_name}</p>
                                                        <p className="text-xs text-gray-500">{act.visitor_phone}</p>
                                                    </div>
                                                    <div className="bg-gray-50 p-2 rounded-lg">
                                                        <p className="text-xs text-gray-500 uppercase font-bold tracking-tighter mb-1">Product</p>
                                                        <p className="text-sm text-gray-700 font-medium line-clamp-1">{act.product_title}</p>
                                                    </div>
                                                    <div className="flex items-center gap-2">
                                                        <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 text-xs font-black">
                                                            {act.reseller_name.charAt(0)}
                                                        </div>
                                                        <div>
                                                            <p className="text-xs font-bold text-gray-900">{act.reseller_name}</p>
                                                            <p className="text-[10px] text-gray-400">Code: {act.referral_code}</p>
                                                        </div>
                                                    </div>
                                                </div>
                                            ))}
                                        </div>
                                    </>
                                ) : (
                                    <div className="text-center py-12 text-gray-500 bg-gray-50 rounded-xl border border-dashed border-gray-300">
                                        No recent activity to display.
                                    </div>
                                )}
                            </div>
                        )}

                        {activeTab === 'products' && (
                            <div>
                                <div className="flex justify-between items-center mb-6">
                                    <h3 className="text-lg font-semibold text-gray-900">Product Management</h3>
                                    <button
                                        onClick={() => navigate('/admin/products/create')}
                                        className="flex items-center gap-2 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors font-medium"
                                    >
                                        <PlusCircleIcon className="w-5 h-5" />
                                        Add Product
                                    </button>
                                </div>
                                <div className="hidden md:block overflow-x-auto">
                                    <table className="w-full text-left">
                                        <thead>
                                            <tr className="border-b border-gray-200">
                                                <th className="pb-4 font-semibold text-gray-600 text-sm">Image</th>
                                                <th className="pb-4 font-semibold text-gray-600 text-sm">Product Details</th>
                                                <th className="pb-4 font-semibold text-gray-600 text-sm">Price</th>
                                                <th className="pb-4 font-semibold text-gray-600 text-sm">Status</th>
                                                <th className="pb-4 font-semibold text-gray-600 text-sm text-right">Actions</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-gray-100">
                                            {products.length === 0 ? (
                                                <tr>
                                                    <td colSpan={5} className="py-8 text-center text-gray-500">
                                                        No products found. Start by adding one!
                                                    </td>
                                                </tr>
                                            ) : (
                                                products.map((product) => (
                                                    <tr key={product.id} className="hover:bg-gray-50/50 transition-colors">
                                                        <td className="py-4">
                                                            <div className="product-image-container product-thumbnail w-16 h-16 rounded-2xl bg-gray-100 overflow-hidden border border-gray-200 shadow-sm">
                                                                {product.thumbnail_url ? (
                                                                    <img
                                                                        src={getImageUrl(product.thumbnail_url)}
                                                                        alt={product.title}
                                                                        className="w-full h-full object-cover"
                                                                        loading="lazy"
                                                                        onError={(e) => {
                                                                            const target = e.target as HTMLImageElement;
                                                                            target.style.display = 'none';
                                                                            const parent = target.parentElement;
                                                                            if (parent) {
                                                                                parent.innerHTML = '<div class="w-full h-full flex items-center justify-center text-gray-400 bg-gray-100"><svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg></div>';
                                                                            }
                                                                        }}
                                                                    />
                                                                ) : (
                                                                    <div className="w-full h-full flex items-center justify-center text-gray-400 bg-gray-100">
                                                                        <PhotoIcon className="w-8 h-8" />
                                                                    </div>
                                                                )}
                                                            </div>
                                                        </td>
                                                        <td className="py-4">
                                                            <p className="font-bold text-gray-900 text-sm">{product.title}</p>
                                                            <div className="flex items-center gap-2 mt-0.5">
                                                                <p className="text-[10px] text-gray-400 font-bold uppercase">Added {formatRelativeTime(product.created_at)}</p>
                                                            </div>
                                                            <p className="text-xs text-gray-500 truncate max-w-xs mt-1">{product.description}</p>
                                                        </td>
                                                        <td className="py-4 font-black text-blue-600 text-sm">
                                                            {formatPrice(product.price)}
                                                        </td>
                                                        <td className="py-4">
                                                            <span className={`px-2.5 py-1 rounded-full text-[10px] font-black tracking-wider ${product.status === 'ACTIVE'
                                                                ? 'bg-green-100 text-green-700'
                                                                : product.status === 'SOLD'
                                                                    ? 'bg-red-100 text-red-700'
                                                                    : 'bg-gray-100 text-gray-700'
                                                                }`}>
                                                                {product.status}
                                                            </span>
                                                        </td>
                                                        <td className="py-4 text-right">
                                                            <div className="flex justify-end gap-3">
                                                                <button
                                                                    className="text-blue-600 hover:text-blue-800 text-xs font-bold"
                                                                    onClick={() => navigate('/admin/products/edit/' + product.id)}
                                                                >
                                                                    Edit
                                                                </button>
                                                                {product.status !== 'SOLD' && (
                                                                    <button
                                                                        className="text-green-600 hover:text-green-800 text-xs font-bold"
                                                                        onClick={() => handleOpenSoldModal(product)}
                                                                    >
                                                                        Mark Sold
                                                                    </button>
                                                                )}
                                                            </div>
                                                        </td>
                                                    </tr>
                                                ))
                                            )}
                                        </tbody>
                                    </table>
                                </div>

                                {/* Mobile Product View */}
                                <div className="md:hidden space-y-4">
                                    {products.length === 0 ? (
                                        <div className="text-center py-12 text-gray-500 bg-gray-50 rounded-xl border border-dashed border-gray-300">
                                            No products found.
                                        </div>
                                    ) : (
                                        products.map((product) => (
                                            <div key={product.id} className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm space-y-4">
                                                <div className="flex gap-4">
                                                    <div className="product-image-container product-thumbnail w-20 h-20 rounded-2xl bg-gray-100 overflow-hidden border border-gray-200 flex-shrink-0">
                                                        {product.thumbnail_url ? (
                                                            <img
                                                                src={getImageUrl(product.thumbnail_url)}
                                                                alt={product.title}
                                                                className="w-full h-full object-cover"
                                                                loading="lazy"
                                                                onError={(e) => {
                                                                    const target = e.target as HTMLImageElement;
                                                                    target.style.display = 'none';
                                                                    const parent = target.parentElement;
                                                                    if (parent) {
                                                                        parent.innerHTML = '<div class="w-full h-full flex items-center justify-center text-gray-400 bg-gray-100"><svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg></div>';
                                                                    }
                                                                }}
                                                            />
                                                        ) : (
                                                            <div className="w-full h-full flex items-center justify-center text-gray-400 bg-gray-100">
                                                                <PhotoIcon className="w-8 h-8" />
                                                            </div>
                                                        )}
                                                    </div>
                                                    <div className="flex-1 min-w-0">
                                                        <div className="flex justify-between items-start">
                                                            <span className={`px-2 py-0.5 rounded-full text-[8px] font-black tracking-widest ${product.status === 'ACTIVE' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-700'}`}>
                                                                {product.status}
                                                            </span>
                                                            <span className="text-[10px] text-gray-400 font-bold uppercase">{formatRelativeTime(product.created_at)}</span>
                                                        </div>
                                                        <h4 className="text-sm font-black text-gray-900 mt-1 truncate">{product.title}</h4>
                                                        <p className="text-lg font-black text-blue-600 mt-0.5">{formatPrice(product.price)}</p>
                                                    </div>
                                                </div>
                                                <div className="flex gap-2 pt-2 border-t border-gray-50">
                                                    <button
                                                        onClick={() => navigate('/admin/products/edit/' + product.id)}
                                                        className="flex-1 py-2.5 bg-gray-900 text-white rounded-xl text-xs font-bold transition-all active:scale-95"
                                                    >
                                                        Edit Project
                                                    </button>
                                                    {product.status !== 'SOLD' && (
                                                        <button
                                                            onClick={() => handleOpenSoldModal(product)}
                                                            className="flex-1 py-2.5 bg-green-500 text-white rounded-xl text-xs font-bold transition-all active:scale-95"
                                                        >
                                                            Mark Sold
                                                        </button>
                                                    )}
                                                </div>
                                            </div>
                                        ))
                                    )}
                                </div>
                                <div className="flex justify-center items-center mt-6 gap-4">
                                    <button
                                        disabled={currentPage === 1}
                                        onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                                        className="px-4 py-2 border border-gray-300 rounded-lg disabled:opacity-50 hover:bg-gray-50 transition-colors"
                                    >
                                        Previous
                                    </button>
                                    <span className="text-sm text-gray-600 font-medium">Page {currentPage} of {totalPages}</span>
                                    <button
                                        disabled={currentPage === totalPages}
                                        onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                                        className="px-4 py-2 border border-gray-300 rounded-lg disabled:opacity-50 hover:bg-gray-50 transition-colors"
                                    >
                                        Next
                                    </button>
                                </div>
                            </div>
                        )}

                        {activeTab === 'resellers' && (
                            <div>
                                <div className="flex justify-between items-center mb-6">
                                    <h3 className="text-lg font-semibold text-gray-900">Reseller Management</h3>
                                    <button
                                        onClick={() => navigate('/admin/resellers/create')}
                                        className="flex items-center gap-2 px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors font-medium"
                                    >
                                        <PlusCircleIcon className="w-5 h-5" />
                                        Add Reseller
                                    </button>
                                </div>
                                <div className="hidden md:block overflow-x-auto">
                                    <table className="w-full text-left">
                                        <thead>
                                            <tr className="border-b border-gray-200">
                                                <th className="pb-4 font-semibold text-gray-600 text-sm">Reseller Name</th>
                                                <th className="pb-4 font-semibold text-gray-600 text-sm">Contact Info</th>
                                                <th className="pb-4 font-semibold text-gray-600 text-sm">Joined Date</th>
                                                <th className="pb-4 font-semibold text-gray-600 text-sm text-right">Action</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-gray-100">
                                            {resellers.length === 0 ? (
                                                <tr>
                                                    <td colSpan={4} className="py-8 text-center text-gray-500">
                                                        No resellers found.
                                                    </td>
                                                </tr>
                                            ) : (
                                                resellers.map((reseller) => (
                                                    <tr key={reseller.id} className="hover:bg-gray-50/50">
                                                        <td className="py-4">
                                                            <div className="flex items-center gap-3">
                                                                <div className="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center text-green-600 font-black text-sm uppercase">
                                                                    {reseller.name.charAt(0)}
                                                                </div>
                                                                <p className="font-bold text-gray-900 text-sm">{reseller.name}</p>
                                                            </div>
                                                        </td>
                                                        <td className="py-4">
                                                            <p className="text-sm text-gray-600">{reseller.email?.String || 'No email'}</p>
                                                            <p className="text-xs text-gray-400 font-medium">{reseller.phone}</p>
                                                        </td>
                                                        <td className="py-4 text-xs text-gray-500 font-medium">
                                                            {new Date(reseller.created_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })}
                                                        </td>
                                                        <td className="py-4 text-right">
                                                            <Link
                                                                to={`/admin/resellers/edit/${reseller.id}`}
                                                                className="text-blue-600 hover:text-blue-800 text-xs font-bold transition-colors inline-block"
                                                            >
                                                                View Details
                                                            </Link>
                                                        </td>
                                                    </tr>
                                                ))
                                            )}
                                        </tbody>
                                    </table>
                                </div>

                                {/* Mobile Reseller View */}
                                <div className="md:hidden space-y-4">
                                    {resellers.length === 0 ? (
                                        <div className="text-center py-12 text-gray-500 bg-gray-50 rounded-xl border border-dashed border-gray-300">
                                            No resellers found.
                                        </div>
                                    ) : (
                                        resellers.map((reseller) => (
                                            <div key={reseller.id} className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm space-y-3">
                                                <div className="flex items-center justify-between">
                                                    <div className="flex items-center gap-3">
                                                        <div className="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center text-green-600 font-black text-xs uppercase">
                                                            {reseller.name.charAt(0)}
                                                        </div>
                                                        <div>
                                                            <p className="text-sm font-black text-gray-900 leading-tight">{reseller.name}</p>
                                                            <p className="text-[10px] text-gray-400 font-bold uppercase tracking-tight">Joined {new Date(reseller.created_at).toLocaleDateString()}</p>
                                                        </div>
                                                    </div>
                                                    <Link
                                                        to={`/admin/resellers/edit/${reseller.id}`}
                                                        className="text-xs font-bold text-blue-600"
                                                    >
                                                        View
                                                    </Link>
                                                </div>
                                                <div className="grid grid-cols-2 gap-2 pt-2">
                                                    <div className="bg-gray-50 p-2 rounded-lg">
                                                        <p className="text-[8px] text-gray-400 font-black uppercase tracking-widest mb-0.5">Email</p>
                                                        <p className="text-[10px] text-gray-700 font-bold truncate">{reseller.email?.String || 'No email'}</p>
                                                    </div>
                                                    <div className="bg-gray-50 p-2 rounded-lg">
                                                        <p className="text-[8px] text-gray-400 font-black uppercase tracking-widest mb-0.5">Phone</p>
                                                        <p className="text-[10px] text-gray-700 font-bold">{reseller.phone}</p>
                                                    </div>
                                                </div>
                                            </div>
                                        ))
                                    )}
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* Sold Modal */}
            {isSoldModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
                    <div className="bg-white rounded-2xl shadow-2xl max-w-lg w-full overflow-hidden">
                        <div className="p-6 border-b border-gray-100 flex justify-between items-center">
                            <div>
                                <h3 className="text-xl font-bold text-gray-900">Mark as Sold</h3>
                                <p className="text-sm text-gray-500">{selectedProductForSold?.title}</p>
                            </div>
                            <button onClick={() => setIsSoldModalOpen(false)} className="text-gray-400 hover:text-gray-600">
                                <XMarkIcon className="w-6 h-6" />
                            </button>
                        </div>
                        <div className="p-6 space-y-4">
                            {/* Units Sold Input - NEW */}
                            <div>
                                <label className="block text-sm font-bold text-gray-700 mb-2">Berapa Unit Terjual? *</label>
                                <div className="flex items-center gap-4">
                                    <div className="flex-1">
                                        <input
                                            type="number"
                                            min="1"
                                            max={selectedProductForSold?.stock || 1}
                                            value={unitsSold}
                                            onChange={(e) => setUnitsSold(parseInt(e.target.value) || 1)}
                                            className="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all text-lg font-bold"
                                        />
                                    </div>
                                    <div className="text-sm">
                                        <p className="text-gray-500">Available:</p>
                                        <p className="text-2xl font-black text-gray-900">{selectedProductForSold?.stock || 0}</p>
                                    </div>
                                </div>
                                <div className="mt-2 p-3 bg-blue-50 rounded-lg border border-blue-100">
                                    <p className="text-sm text-blue-700">
                                        <span className="font-bold">Remaining:</span> {(selectedProductForSold?.stock || 0) - unitsSold} unit(s)
                                        {((selectedProductForSold?.stock || 0) - unitsSold) === 0 && (
                                            <span className="ml-2 text-red-600">⚠️ Product will be marked as SOLD</span>
                                        )}
                                    </p>
                                </div>
                            </div>

                            <label className="block text-sm font-medium text-gray-700">Pilih Pembeli (Leads)</label>
                            <p className="text-xs text-gray-500 mb-2">Pilih lead yang akhirnya membeli produk ini untuk mencatatkan komisi ke reseller terkait.</p>

                            <div className="space-y-2 max-h-60 overflow-y-auto pr-2 custom-scrollbar">
                                {productLeads.length > 0 ? (
                                    productLeads.map((lead) => (
                                        <button
                                            key={lead.id}
                                            onClick={() => setSelectedLeadId(lead.id)}
                                            className={`w-full text-left p-4 rounded-xl border-2 transition-all ${selectedLeadId === lead.id
                                                ? 'border-blue-500 bg-blue-50'
                                                : 'border-gray-100 hover:border-gray-200 bg-gray-50'
                                                }`}
                                        >
                                            <div className="flex justify-between items-start">
                                                <div>
                                                    <p className="font-bold text-gray-900">{lead.visitor_name}</p>
                                                    <p className="text-sm text-gray-500">{lead.visitor_phone}</p>
                                                </div>
                                                <div className="text-right">
                                                    <p className="text-xs font-medium text-blue-600">Ref: {lead.referral_code}</p>
                                                    <p className="text-xs text-gray-400">{lead.reseller_name}</p>
                                                </div>
                                            </div>
                                        </button>
                                    ))
                                ) : (
                                    <div className="text-center py-8 bg-gray-50 rounded-xl border border-dashed border-gray-300">
                                        <p className="text-gray-500 text-sm">Tidak ada lead untuk produk ini.</p>
                                    </div>
                                )}

                                <button
                                    onClick={() => setSelectedLeadId('')}
                                    className={`w-full text-left p-4 rounded-xl border-2 transition-all ${selectedLeadId === ''
                                        ? 'border-gray-500 bg-gray-50'
                                        : 'border-gray-100 hover:border-gray-200 bg-white'
                                        }`}
                                >
                                    <p className="font-bold text-gray-900">Direct Sale (Tanpa Reseller)</p>
                                    <p className="text-sm text-gray-500">Pilih jika terjual langsung tanpa melalui link reseller.</p>
                                </button>
                            </div>
                        </div>
                        <div className="p-6 bg-gray-50 flex justify-end gap-3">
                            <button
                                onClick={() => setIsSoldModalOpen(false)}
                                className="px-6 py-2.5 text-gray-700 font-medium hover:text-gray-900 transition-colors"
                            >
                                Batal
                            </button>
                            <button
                                onClick={handleConfirmSold}
                                disabled={isFinalizingSold}
                                className={`px-8 py-2.5 rounded-xl font-bold text-white shadow-lg transition-all ${isFinalizingSold ? 'bg-gray-400 cursor-not-allowed' : 'bg-blue-600 hover:bg-blue-700 active:scale-95'
                                    }`}
                            >
                                {isFinalizingSold ? 'Memproses...' : 'Konfirmasi Terjual'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default AdminDashboard;
