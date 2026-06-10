import { useEffect, useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { ErrorBoundary } from '../../components/ErrorBoundary';
import {
    ChartBarIcon,
    UserGroupIcon,
    ShoppingBagIcon,
    PlusCircleIcon,
    ArrowRightOnRectangleIcon,
    PhotoIcon,
    HomeIcon,
    XMarkIcon,
    Cog6ToothIcon
} from '@heroicons/react/24/outline';
import client from '../../api/client';
import { getImageUrl } from '../../utils/image';
import { formatRelativeTime } from '../../utils/date';

const AdminDashboard = () => {
    const navigate = useNavigate();
    const [stats, setStats] = useState<any>(null);
    const [products, setProducts] = useState<any[]>([]);
    const [resellers, setResellers] = useState<any[]>([]);
    const [members, setMembers] = useState<any[]>([]);
    const [activeTab, setActiveTab] = useState<'overview' | 'products' | 'resellers' | 'members' | 'settings'>('overview');
    const [loading, setLoading] = useState(true);
    const [configs, setConfigs] = useState<any[]>([]);
    const [configValues, setConfigValues] = useState<Record<string, string>>({
        member_registration_fee: '',
        reseller_registration_fee: '',
        admin_whatsapp_number: '',
        minimum_withdrawal_amount: '',
        max_withdrawals_per_day: '',
        reseller_referral_commission: '',
    });
    const [loadingConfigs, setLoadingConfigs] = useState(false);
    const [savingConfigs, setSavingConfigs] = useState(false);

    // Pagination
    const [currentPage, setCurrentPage] = useState(1);
    const [totalPages, setTotalPages] = useState(1);
    const [limit] = useState(5);

    // Sold Logic
    const [isSoldModalOpen, setIsSoldModalOpen] = useState(false);
    const [selectedProductForSold, setSelectedProductForSold] = useState<any>(null);
    const [productLeads, setProductLeads] = useState<any[]>([]);
    const [martClients, setMartClients] = useState<any[]>([]);
    const [selectedLeadId, setSelectedLeadId] = useState('');
    const [selectedMartClientId, setSelectedMartClientId] = useState('');
    const [clientSearchQuery, setClientSearchQuery] = useState('');
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
        } else if (activeTab === 'members') {
            loadMembers();
        } else if (activeTab === 'settings') {
            loadConfigs();
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
        } catch (err: any) {
            console.error('Failed to load dashboard', err);
            if (err.response?.status === 401) {
                navigate('/auth/login/admin');
            }
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
        } catch (err: any) {
            console.error('Failed to load products', err);
            if (err.response?.status === 401) {
                navigate('/auth/login/admin');
            }
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
        } catch (err: any) {
            console.error('Failed to load resellers', err);
            if (err.response?.status === 401) {
                navigate('/auth/login/admin');
            }
        }
    };

    const loadMembers = async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await client.get('/admin/members', {
                headers: { Authorization: `Bearer ${token}` }
            });
            if (res.data && res.data.message_data) {
                setMembers(res.data.message_data);
            }
        } catch (err: any) {
            console.error('Failed to load members', err);
            if (err.response?.status === 401) {
                navigate('/auth/login/admin');
            }
        }
    };

    const loadConfigs = async () => {
        setLoadingConfigs(true);
        try {
            const token = localStorage.getItem('token');
            const res = await client.get('/admin/configs', {
                headers: { Authorization: `Bearer ${token}` }
            });
            if (res.data && res.data.message_data) {
                const cfgs: any[] = Array.isArray(res.data.message_data) ? res.data.message_data : [];
                setConfigs(cfgs);
                const vals: Record<string, string> = { ...configValues };
                cfgs.forEach((c: any) => {
                    if (c.key in vals) vals[c.key] = c.value;
                });
                setConfigValues(vals);
            }
        } catch (err: any) {
            console.error('Failed to load configs', err);
        } finally {
            setLoadingConfigs(false);
        }
    };

    const handleSaveConfigs = async () => {
        setSavingConfigs(true);
        try {
            const token = localStorage.getItem('token');
            const payload = {
                configs: Object.entries(configValues).map(([key, value]) => ({
                    key,
                    value,
                    description: configs.find((c: any) => c.key === key)?.description?.String || configs.find((c: any) => c.key === key)?.description || '',
                }))
            };
            await client.put('/admin/configs', payload, {
                headers: { Authorization: `Bearer ${token}` }
            });
            alert('Konfigurasi berhasil disimpan!');
            loadConfigs();
        } catch (err: any) {
            console.error('Failed to save configs', err);
            const msg = err.response?.data?.error || err.response?.data?.message || 'Gagal menyimpan konfigurasi';
            alert(msg);
        } finally {
            setSavingConfigs(false);
        }
    };

    const handleApproveMember = async (id: string) => {
        try {
            const token = localStorage.getItem('token');
            const memberToApprove = members.find((m: any) => m.id === id);
            if (!memberToApprove) return;

            await client.put(`/admin/members/${id}`, {
                name: memberToApprove.name,
                phone: memberToApprove.phone,
                email: memberToApprove.email?.String || memberToApprove.email || '',
                status: 'ACTIVE'
            }, {
                headers: { Authorization: `Bearer ${token}` }
            });
            alert('Member approved successfully!');
            loadMembers();
        } catch (err) {
            console.error('Failed to approve member', err);
            alert('Failed to approve member');
        }
    };

    const handleDeclineMember = async (id: string) => {
        if (!window.confirm('Are you sure you want to decline and block this registration?')) return;
        try {
            const token = localStorage.getItem('token');
            const memberToDecline = members.find((m: any) => m.id === id);
            if (!memberToDecline) return;

            await client.put(`/admin/members/${id}`, {
                name: memberToDecline.name,
                phone: memberToDecline.phone,
                email: memberToDecline.email?.String || memberToDecline.email || '',
                status: 'BLOCKED'
            }, {
                headers: { Authorization: `Bearer ${token}` }
            });
            alert('Member registration declined!');
            loadMembers();
        } catch (err) {
            console.error('Failed to decline member', err);
            alert('Failed to decline member');
        }
    };

    const handleLogout = () => {
        localStorage.removeItem('token');
        localStorage.removeItem('role');
        navigate('/');
    };

    const loadMartClients = async (search: string = '') => {
        try {
            const token = localStorage.getItem('token');
            const resClients = await client.get(`/admin/mart-clients?q=${search}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            if (resClients.data && resClients.data.message_data) {
                setMartClients(Array.isArray(resClients.data.message_data) ? resClients.data.message_data : []);
            }
        } catch (err: any) {
            console.error('Failed to load mart clients', err);
        }
    };

    const handleOpenSoldModal = async (product: any) => {
        try {
            setSelectedProductForSold(product);
            setIsSoldModalOpen(true);
            setProductLeads([]);
            setMartClients([]);
            setSelectedLeadId('');
            setSelectedMartClientId('');
            setClientSearchQuery('');
            setUnitsSold(1); // Reset to 1 unit

            const token = localStorage.getItem('token');
            const res = await client.get(`/admin/products/${product.id}/leads`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            if (res.data && res.data.message_data) {
                setProductLeads(Array.isArray(res.data.message_data) ? res.data.message_data : []);
            }

            loadMartClients(''); // Load all clients initially
        } catch (err: any) {
            console.error('Failed to load product leads or open modal', err);
            alert("Error in handleOpenSoldModal: " + (err.message || String(err)));
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
                lead_id: selectedLeadId,
                mart_client_id: selectedMartClientId
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
            title: 'Total Members',
            value: stats?.total_members || 0,
            icon: UserGroupIcon,
            color: 'bg-gradient-to-br from-indigo-500 to-indigo-600',
            iconBg: 'bg-indigo-100',
            iconColor: 'text-indigo-600'
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
        <ErrorBoundary>
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
                                { key: 'members', label: 'Members', icon: UserGroupIcon, badge: members.filter((m: any) => m.status === 'PENDING').length },
                                { key: 'settings', label: 'Pengaturan', icon: Cog6ToothIcon },
                            ].map((tab) => (
                                <button
                                    key={tab.key}
                                    onClick={() => setActiveTab(tab.key as any)}
                                    className={`relative flex items-center gap-2 px-6 py-3.5 text-xs sm:text-sm font-black rounded-xl transition-all ${activeTab === tab.key
                                        ? 'bg-blue-50 text-blue-600 shadow-sm'
                                        : 'text-gray-500 hover:text-gray-900 hover:bg-gray-50'
                                        }`}
                                >
                                    <tab.icon className="w-4 h-4 sm:w-5 sm:h-5" />
                                    {tab.label}
                                    {tab.badge ? (
                                        <span className="absolute -top-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-red-500 text-[10px] font-bold text-white shadow-sm ring-2 ring-white">
                                            {tab.badge}
                                        </span>
                                    ) : null}
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
                                                    {(Array.isArray(stats.recent_activities) ? [...stats.recent_activities] : []).sort((a: any, b: any) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()).map((act: any, idx: number) => (
                                                        <tr key={idx} className="hover:bg-blue-50/50 transition-colors">
                                                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                                                {new Date(act.created_at).toLocaleString('id-ID')}
                                                            </td>
                                                            <td className="px-6 py-4 whitespace-nowrap">
                                                                <div className="text-sm font-medium text-gray-900">{act.visitor_name?.String || (typeof act.visitor_name === 'string' ? act.visitor_name : 'Unknown')}</div>
                                                                <div className="text-sm text-gray-500">{act.visitor_phone?.String || (typeof act.visitor_phone === 'string' ? act.visitor_phone : 'No phone')}</div>
                                                            </td>
                                                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                                                {act.type === 'MEMBER_REGISTRATION' ? (
                                                                    <span className="px-2.5 py-1 bg-yellow-100 text-yellow-800 rounded-lg font-black text-[10px] uppercase tracking-wider">New Member Registration</span>
                                                                ) : (
                                                                    act.product_title
                                                                )}
                                                            </td>
                                                            <td className="px-6 py-4 whitespace-nowrap">
                                                                {act.type === 'MEMBER_REGISTRATION' ? (
                                                                    <div className="text-sm font-medium text-gray-400 italic">Self Registration</div>
                                                                ) : (
                                                                    <>
                                                                        <div className="text-sm font-medium text-blue-600">{act.reseller_name}</div>
                                                                        <div className="text-xs text-gray-500">{act.referral_code}</div>
                                                                    </>
                                                                )}
                                                            </td>
                                                            <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                                                {act.type === 'MEMBER_REGISTRATION' ? (
                                                                    <Link to={`/admin/members/edit/${act.member_id}`} className="text-indigo-600 hover:text-indigo-900 font-black">
                                                                        Review & Approve
                                                                    </Link>
                                                                ) : (
                                                                    <a href={`/products/${act.product_id}`} target="_blank" rel="noreferrer" className="text-blue-600 hover:text-blue-900">
                                                                        View
                                                                    </a>
                                                                )}
                                                            </td>
                                                        </tr>
                                                    ))}

                                                </tbody>
                                            </table>
                                        </div>
                                        {/* Mobile View Activity */}
                                        <div className="md:hidden space-y-4">
                                            {(Array.isArray(stats.recent_activities) ? [...stats.recent_activities] : []).sort((a: any, b: any) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()).map((act: any, idx: number) => (
                                                <div key={idx} className="bg-white p-4 rounded-xl border border-gray-200 space-y-3">
                                                    <div className="flex justify-between items-start">
                                                        <span className={`text-[10px] font-bold px-2 py-0.5 rounded uppercase ${
                                                            act.type === 'MEMBER_REGISTRATION' ? 'bg-yellow-100 text-yellow-700' : 'text-gray-400 border border-gray-100'
                                                        }`}>
                                                            {act.type === 'MEMBER_REGISTRATION' ? 'New Member' : new Date(act.created_at).toLocaleTimeString('id-ID')}
                                                        </span>
                                                        {act.type === 'MEMBER_REGISTRATION' ? (
                                                            <Link to={`/admin/members/edit/${act.member_id}`} className="text-xs font-bold text-indigo-600 underline">
                                                                Review Member
                                                            </Link>
                                                        ) : (
                                                            <a href={`/products/${act.product_id}`} target="_blank" rel="noreferrer" className="text-xs font-bold text-blue-600">
                                                                View Product
                                                            </a>
                                                        )}
                                                    </div>
                                                    <div>
                                                        <p className="text-sm font-bold text-gray-900">{act.visitor_name?.String || (typeof act.visitor_name === 'string' ? act.visitor_name : 'Unknown')}</p>
                                                        <p className="text-xs text-gray-500">{act.visitor_phone?.String || (typeof act.visitor_phone === 'string' ? act.visitor_phone : 'No phone')}</p>
                                                    </div>
                                                    <div className="bg-gray-50 p-2 rounded-lg">
                                                        <p className="text-xs text-gray-500 uppercase font-bold tracking-tighter mb-1">
                                                            {act.type === 'MEMBER_REGISTRATION' ? 'Note' : 'Product'}
                                                        </p>
                                                        <p className="text-sm text-gray-700 font-medium line-clamp-1">{act.product_title}</p>
                                                    </div>
                                                    <div className="flex items-center gap-2">
                                                        <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 text-xs font-black">
                                                            {((act.reseller_name || act.visitor_name?.String || (typeof act.visitor_name === 'string' ? act.visitor_name : '') || '?')).charAt(0)}
                                                        </div>
                                                        <div>
                                                            <p className="text-xs font-bold text-gray-900">{act.reseller_name || 'Self Registration'}</p>
                                                            <p className="text-[10px] text-gray-400">{act.referral_code ? `Code: ${act.referral_code}` : 'New Signup'}</p>
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
                                                                        onClick={(e) => {
                                                                            e.preventDefault();
                                                                            e.stopPropagation();
                                                                            handleOpenSoldModal(product).catch(err => {
                                                                                console.error(err);
                                                                                alert("Error opening modal: " + err.message);
                                                                            });
                                                                        }}
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
                                                            onClick={(e) => {
                                                                e.preventDefault();
                                                                e.stopPropagation();
                                                                handleOpenSoldModal(product).catch(err => {
                                                                    console.error(err);
                                                                    alert("Error opening modal: " + err.message);
                                                                });
                                                            }}
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
                                                <th className="pb-4 font-semibold text-gray-600 text-sm">Member (Leader)</th>
                                                <th className="pb-4 font-semibold text-gray-600 text-sm">Contact Info</th>
                                                <th className="pb-4 font-semibold text-gray-600 text-sm">Joined Date</th>
                                                <th className="pb-4 font-semibold text-gray-600 text-sm text-right">Action</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-gray-100">
                                            {resellers.length === 0 ? (
                                                <tr>
                                                    <td colSpan={5} className="py-8 text-center text-gray-500">
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
                                                            <div className="flex items-center gap-2">
                                                                {reseller.member_name?.String ? (
                                                                    <div className="flex flex-col">
                                                                        <span className="text-sm font-bold text-indigo-600">{reseller.member_name.String}</span>
                                                                        <span className="text-[10px] text-gray-400 font-medium uppercase">Managed By</span>
                                                                    </div>
                                                                ) : (
                                                                    <span className="text-xs text-gray-400 italic">No Leader</span>
                                                                )}
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
                                                {reseller.member_name?.String && (
                                                    <div className="mt-2 px-3 py-2 bg-indigo-50 rounded-xl border border-indigo-100 flex items-center justify-between">
                                                        <span className="text-[9px] font-black text-indigo-400 uppercase tracking-tighter">Leader</span>
                                                        <span className="text-xs font-black text-indigo-700">{reseller.member_name.String}</span>
                                                    </div>
                                                )}
                                            </div>
                                        ))
                                    )}
                                </div>
                            </div>
                        )}

                        {activeTab === 'members' && (
                            <div>
                                {members.filter((m: any) => m.status === 'PENDING').length > 0 && (
                                    <div className="mb-8 bg-yellow-50 rounded-2xl border border-yellow-200 p-6 shadow-sm">
                                        <div className="flex items-center gap-3 mb-4">
                                            <div className="p-2 bg-yellow-100 rounded-lg">
                                                <UserGroupIcon className="w-5 h-5 text-yellow-700" />
                                            </div>
                                            <h3 className="text-lg font-bold text-yellow-900">Pending Registrations</h3>
                                        </div>
                                        <div className="grid gap-4 md:grid-cols-2">
                                            {members.filter((m: any) => m.status === 'PENDING').map((pendingMember) => (
                                                <div key={pendingMember.id} className="bg-white rounded-xl p-5 border border-yellow-100 shadow-sm space-y-4">
                                                    <div className="flex justify-between items-start">
                                                        <div className="flex items-center gap-3">
                                                            {pendingMember.profile_image?.String ? (
                                                                <img src={getImageUrl(pendingMember.profile_image.String)} alt="Profile" className="w-12 h-12 rounded-full object-cover border border-gray-200" />
                                                            ) : (
                                                                <div className="w-12 h-12 bg-indigo-100 rounded-full flex items-center justify-center text-indigo-600 font-black text-lg uppercase">
                                                                    {pendingMember.name.charAt(0)}
                                                                </div>
                                                            )}
                                                            <div>
                                                                <p className="font-bold text-gray-900">{pendingMember.name}</p>
                                                                <p className="text-xs text-gray-500">@{pendingMember.username?.String || 'no_username'}</p>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    
                                                    <div className="grid grid-cols-2 gap-3 text-xs bg-gray-50 p-3 rounded-lg border border-gray-100">
                                                        <div>
                                                            <span className="block text-gray-400 font-bold mb-0.5">NIK</span>
                                                            <span className="font-semibold text-gray-800">{pendingMember.nik?.String || '-'}</span>
                                                        </div>
                                                        <div>
                                                            <span className="block text-gray-400 font-bold mb-0.5">Phone</span>
                                                            <span className="font-semibold text-gray-800">{pendingMember.phone}</span>
                                                        </div>
                                                        <div className="col-span-2">
                                                            <span className="block text-gray-400 font-bold mb-0.5">Email</span>
                                                            <span className="font-semibold text-gray-800">{pendingMember.email?.String || '-'}</span>
                                                        </div>
                                                    </div>

                                                    {pendingMember.ktp_image?.String && (
                                                        <div>
                                                            <a href={getImageUrl(pendingMember.ktp_image.String)} target="_blank" rel="noreferrer" className="text-xs text-blue-600 hover:text-blue-800 font-bold flex items-center gap-1">
                                                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" /></svg>
                                                                View KTP Image
                                                            </a>
                                                        </div>
                                                    )}

                                                    <div className="flex gap-2 pt-2 border-t border-gray-100">
                                                        <button 
                                                            onClick={() => handleApproveMember(pendingMember.id)}
                                                            className="flex-1 bg-green-500 hover:bg-green-600 text-white py-2 rounded-lg text-sm font-bold transition-colors"
                                                        >
                                                            Approve
                                                        </button>
                                                        <button 
                                                            onClick={() => handleDeclineMember(pendingMember.id)}
                                                            className="flex-1 bg-red-50 hover:bg-red-100 text-red-600 border border-red-200 py-2 rounded-lg text-sm font-bold transition-colors"
                                                        >
                                                            Decline
                                                        </button>
                                                    </div>
                                                </div>
                                            ))}
                                        </div>
                                    </div>
                                )}

                                <div className="flex justify-between items-center mb-6">
                                    <h3 className="text-lg font-semibold text-gray-900">Active Members</h3>
                                    <button
                                        onClick={() => navigate('/admin/members/create')}
                                        className="flex items-center gap-2 px-4 py-2 bg-indigo-500 text-white rounded-lg hover:bg-indigo-600 transition-colors font-medium"
                                    >
                                        <PlusCircleIcon className="w-5 h-5" />
                                        Add Member
                                    </button>
                                </div>
                                <div className="hidden md:block overflow-x-auto">
                                    <table className="w-full text-left">
                                        <thead>
                                            <tr className="border-b border-gray-200">
                                                <th className="pb-4 font-semibold text-gray-600 text-sm">Member Name</th>
                                                <th className="pb-4 font-semibold text-gray-600 text-sm">Contact Info</th>
                                                <th className="pb-4 font-semibold text-gray-600 text-sm">Joined Date</th>
                                                <th className="pb-4 font-semibold text-gray-600 text-sm text-right">Action</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-gray-100">
                                            {members.filter((m: any) => m.status !== 'PENDING').length === 0 ? (
                                                <tr>
                                                    <td colSpan={4} className="py-8 text-center text-gray-500">
                                                        No active members found.
                                                    </td>
                                                </tr>
                                            ) : (
                                                members.filter((m: any) => m.status !== 'PENDING').map((member) => (
                                                    <tr key={member.id} className="hover:bg-gray-50/50">
                                                        <td className="py-4">
                                                            <div className="flex items-center gap-3">
                                                                <div className="flex-shrink-0 w-10 h-10">
                                                                    {member.profile_image?.String ? (
                                                                        <img 
                                                                            src={getImageUrl(member.profile_image.String)} 
                                                                            alt="" 
                                                                            className="w-10 h-10 rounded-full object-cover border border-gray-200 shadow-sm"
                                                                            style={{ width: '40px', height: '40px', minWidth: '40px', maxWidth: '40px' }}
                                                                        />
                                                                    ) : (
                                                                        <div className="w-10 h-10 bg-indigo-100 rounded-full flex items-center justify-center text-indigo-600 font-black text-sm uppercase border border-indigo-200">
                                                                            {member.name.charAt(0)}
                                                                        </div>
                                                                    )}
                                                                </div>
                                                                <div className="min-w-0">
                                                                    <p className="font-bold text-gray-900 text-sm truncate max-w-[120px]">{member.name}</p>
                                                                    <div className="flex gap-1 mt-0.5">
                                                                        {member.status === 'PENDING' && <span className="text-[9px] bg-yellow-100 text-yellow-700 px-1.5 py-0.5 rounded-md font-black uppercase tracking-tighter">PENDING</span>}
                                                                        {member.status === 'ACTIVE' && <span className="text-[9px] bg-green-100 text-green-700 px-1.5 py-0.5 rounded-md font-black uppercase tracking-tighter">ACTIVE</span>}
                                                                        {member.status === 'BLOCKED' && <span className="text-[9px] bg-red-100 text-red-700 px-1.5 py-0.5 rounded-md font-black uppercase tracking-tighter">BLOCKED</span>}
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </td>
                                                        <td className="py-4 px-4">
                                                            <div className="flex flex-col">
                                                                <p className="text-sm text-gray-900 font-bold leading-tight">{member.username?.String || 'No Username'}</p>
                                                                <p className="text-[10px] text-gray-500 font-medium">NIK: {member.nik?.String || '-'}</p>
                                                                <p className="text-[10px] text-gray-400 truncate max-w-[150px]">{member.email?.String}</p>
                                                            </div>
                                                        </td>


                                                        <td className="py-4 text-xs text-gray-500 font-medium">
                                                            {new Date(member.created_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })}
                                                        </td>
                                                        <td className="py-4 text-right">
                                                            <Link
                                                                to={`/admin/members/edit/${member.id}`}
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

                                {/* Mobile Member View */}
                                <div className="md:hidden space-y-4">
                                    {members.length === 0 ? (
                                        <div className="text-center py-12 text-gray-500 bg-gray-50 rounded-xl border border-dashed border-gray-300">
                                            No members found.
                                        </div>
                                    ) : (
                                        members.map((member) => (
                                            <div key={member.id} className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm space-y-3">
                                                <div className="flex items-center justify-between">
                                                    <div className="flex items-center gap-3">
                                                        <div className="w-10 h-10 bg-indigo-100 rounded-full flex items-center justify-center text-indigo-600 font-black text-xs uppercase">
                                                            {member.name.charAt(0)}
                                                        </div>
                                                        <div>
                                                            <p className="text-sm font-black text-gray-900 leading-tight">{member.name}</p>
                                                            <p className="text-[10px] text-gray-400 font-bold uppercase tracking-tight">Joined {new Date(member.created_at).toLocaleDateString()}</p>
                                                        </div>
                                                    </div>
                                                    <Link
                                                        to={`/admin/members/edit/${member.id}`}
                                                        className="text-xs font-bold text-blue-600"
                                                    >
                                                        View
                                                    </Link>
                                                </div>
                                                <div className="grid grid-cols-2 gap-2 pt-2">
                                                    <div className="bg-gray-50 p-2 rounded-lg">
                                                        <p className="text-[8px] text-gray-400 font-black uppercase tracking-widest mb-0.5">Email</p>
                                                        <p className="text-[10px] text-gray-700 font-bold truncate">{member.email?.String || 'No email'}</p>
                                                    </div>
                                                    <div className="bg-gray-50 p-2 rounded-lg">
                                                        <p className="text-[8px] text-gray-400 font-black uppercase tracking-widest mb-0.5">Phone</p>
                                                        <p className="text-[10px] text-gray-700 font-bold">{member.phone}</p>
                                                    </div>
                                                </div>
                                            </div>
                                        ))
                                    )}
                                </div>
                            </div>
                        )}

                        {activeTab === 'settings' && (
                            <div className="space-y-8">
                                <div className="flex items-center justify-between">
                                    <div>
                                        <h3 className="text-xl font-bold text-gray-900">Pengaturan Sistem</h3>
                                        <p className="text-sm text-gray-500 mt-1">Kelola konfigurasi aplikasi secara dinamis</p>
                                    </div>
                                    <button
                                        onClick={handleSaveConfigs}
                                        disabled={savingConfigs || loadingConfigs}
                                        className={`flex items-center gap-2 px-6 py-2.5 rounded-xl font-bold text-white shadow-lg transition-all ${savingConfigs ? 'bg-gray-400 cursor-not-allowed' : 'bg-blue-600 hover:bg-blue-700 active:scale-95'}`}
                                    >
                                        {savingConfigs ? (
                                            <>
                                                <svg className="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                                                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                                                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                                                </svg>
                                                Menyimpan...
                                            </>
                                        ) : (
                                            <>
                                                <Cog6ToothIcon className="w-4 h-4" />
                                                Simpan Semua
                                            </>
                                        )}
                                    </button>
                                </div>

                                {loadingConfigs ? (
                                    <div className="grid gap-6 md:grid-cols-3">
                                        {[1, 2, 3].map(i => (
                                            <div key={i} className="bg-gray-50 rounded-2xl p-6 animate-pulse">
                                                <div className="h-4 bg-gray-200 rounded mb-4 w-3/4" />
                                                <div className="h-10 bg-gray-200 rounded" />
                                            </div>
                                        ))}
                                    </div>
                                ) : (
                                    <>
                                        {/* Section: Biaya Pendaftaran */}
                                        <div className="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-2xl p-6 border border-blue-100">
                                            <div className="flex items-center gap-3 mb-6">
                                                <div className="p-2.5 bg-blue-100 rounded-xl">
                                                    <svg className="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
                                                    </svg>
                                                </div>
                                                <div>
                                                    <h4 className="font-bold text-blue-900 text-base">Biaya Pendaftaran</h4>
                                                    <p className="text-xs text-blue-600">Biaya yang dibayar melalui DANA saat registrasi</p>
                                                </div>
                                            </div>
                                            <div className="grid gap-4 md:grid-cols-2">
                                                <div>
                                                    <label className="block text-sm font-bold text-gray-700 mb-2">
                                                        Biaya Pendaftaran Member (Rp)
                                                    </label>
                                                    <div className="relative">
                                                        <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 font-bold text-sm">Rp</span>
                                                        <input
                                                            type="number"
                                                            min="0"
                                                            value={configValues.member_registration_fee}
                                                            onChange={e => setConfigValues(v => ({ ...v, member_registration_fee: e.target.value }))}
                                                            className="w-full pl-10 pr-4 py-3 border-2 border-blue-200 rounded-xl bg-white focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all font-bold text-gray-900"
                                                            placeholder="10000"
                                                        />
                                                    </div>
                                                    <p className="text-xs text-gray-500 mt-1">Default: Rp 10.000</p>
                                                </div>
                                                <div>
                                                    <label className="block text-sm font-bold text-gray-700 mb-2">
                                                        Biaya Pendaftaran Reseller (Rp)
                                                    </label>
                                                    <div className="relative">
                                                        <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 font-bold text-sm">Rp</span>
                                                        <input
                                                            type="number"
                                                            min="0"
                                                            value={configValues.reseller_registration_fee}
                                                            onChange={e => setConfigValues(v => ({ ...v, reseller_registration_fee: e.target.value }))}
                                                            className="w-full pl-10 pr-4 py-3 border-2 border-blue-200 rounded-xl bg-white focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all font-bold text-gray-900"
                                                            placeholder="50000"
                                                        />
                                                    </div>
                                                    <p className="text-xs text-gray-500 mt-1">Default: Rp 50.000</p>
                                                </div>
                                            </div>
                                        </div>

                                        {/* Section: Komisi Referral */}
                                        <div className="bg-gradient-to-br from-purple-50 to-indigo-50 rounded-2xl p-6 border border-purple-100">
                                            <div className="flex items-center gap-3 mb-6">
                                                <div className="p-2.5 bg-purple-100 rounded-xl">
                                                    <svg className="w-5 h-5 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                                                    </svg>
                                                </div>
                                                <div>
                                                    <h4 className="font-bold text-purple-900 text-base">Komisi Referral</h4>
                                                    <p className="text-xs text-purple-600">Komisi yang didapatkan oleh Member/Leader saat ada reseller mendaftar</p>
                                                </div>
                                            </div>
                                            <div>
                                                <label className="block text-sm font-bold text-gray-700 mb-2">
                                                    Komisi Registrasi Reseller (Rp)
                                                </label>
                                                <div className="relative">
                                                    <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 font-bold text-sm">Rp</span>
                                                    <input
                                                        type="number"
                                                        min="0"
                                                        value={configValues.reseller_referral_commission}
                                                        onChange={e => setConfigValues(v => ({ ...v, reseller_referral_commission: e.target.value }))}
                                                        className="w-full pl-10 pr-4 py-3 border-2 border-purple-200 rounded-xl bg-white focus:border-purple-500 focus:ring-2 focus:ring-purple-100 transition-all font-bold text-gray-900"
                                                        placeholder="10000"
                                                    />
                                                </div>
                                                <p className="text-xs text-gray-500 mt-1">Default: Rp 10.000. Diberikan saat reseller yang diajak resmi aktif.</p>
                                            </div>
                                        </div>

                                        {/* Section: Kontak Admin */}
                                        <div className="bg-gradient-to-br from-green-50 to-emerald-50 rounded-2xl p-6 border border-green-100">
                                            <div className="flex items-center gap-3 mb-6">
                                                <div className="p-2.5 bg-green-100 rounded-xl">
                                                    <svg className="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                                                    </svg>
                                                </div>
                                                <div>
                                                    <h4 className="font-bold text-green-900 text-base">Kontak Admin</h4>
                                                    <p className="text-xs text-green-600">Nomor WA untuk tombol "Hubungi Penjual" di Gostar Mart App</p>
                                                </div>
                                            </div>
                                            <div>
                                                <label className="block text-sm font-bold text-gray-700 mb-2">
                                                    Nomor WhatsApp Admin
                                                </label>
                                                <div className="relative">
                                                    <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 font-bold text-sm">+</span>
                                                    <input
                                                        type="text"
                                                        value={configValues.admin_whatsapp_number}
                                                        onChange={e => setConfigValues(v => ({ ...v, admin_whatsapp_number: e.target.value.replace(/\D/g, '') }))}
                                                        className="w-full pl-8 pr-4 py-3 border-2 border-green-200 rounded-xl bg-white focus:border-green-500 focus:ring-2 focus:ring-green-100 transition-all font-bold text-gray-900"
                                                        placeholder="628123456789"
                                                        maxLength={15}
                                                    />
                                                </div>
                                                <p className="text-xs text-gray-500 mt-1">Format tanpa tanda + atau spasi. Contoh: 628123456789</p>
                                                {configValues.admin_whatsapp_number && (
                                                    <a
                                                        href={`https://wa.me/${configValues.admin_whatsapp_number}`}
                                                        target="_blank"
                                                        rel="noreferrer"
                                                        className="mt-2 inline-flex items-center gap-1.5 text-xs text-green-700 font-bold hover:text-green-900 transition-colors"
                                                    >
                                                        <svg className="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24">
                                                            <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
                                                        </svg>
                                                        Test link WhatsApp
                                                    </a>
                                                )}
                                            </div>
                                        </div>

                                        {/* Section: Batas Keuangan */}
                                        <div className="bg-gradient-to-br from-orange-50 to-amber-50 rounded-2xl p-6 border border-orange-100">
                                            <div className="flex items-center gap-3 mb-6">
                                                <div className="p-2.5 bg-orange-100 rounded-xl">
                                                    <svg className="w-5 h-5 text-orange-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                                                    </svg>
                                                </div>
                                                <div>
                                                    <h4 className="font-bold text-orange-900 text-base">Batas Keuangan</h4>
                                                    <p className="text-xs text-orange-600">Aturan withdraw untuk reseller.</p>
                                                </div>
                                            </div>
                                            <div className="grid gap-4 md:grid-cols-2">
                                                <div>
                                                    <label className="block text-sm font-bold text-gray-700 mb-2">
                                                        Minimum Penarikan (Rp)
                                                    </label>
                                                    <div className="relative">
                                                        <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 font-bold text-sm">Rp</span>
                                                        <input
                                                            type="number"
                                                            min="0"
                                                            value={configValues.minimum_withdrawal_amount}
                                                            onChange={e => setConfigValues(v => ({ ...v, minimum_withdrawal_amount: e.target.value }))}
                                                            className="w-full pl-10 pr-4 py-3 border-2 border-orange-200 rounded-xl bg-white focus:border-orange-500 focus:ring-2 focus:ring-orange-100 transition-all font-bold text-gray-900"
                                                            placeholder="20000"
                                                        />
                                                    </div>
                                                    <p className="text-xs text-gray-500 mt-1">Default: Rp 20.000. Reseller tidak bisa menarik di bawah jumlah ini.</p>
                                                </div>
                                                <div>
                                                    <label className="block text-sm font-bold text-gray-700 mb-2">
                                                        Maksimal Penarikan per Hari
                                                    </label>
                                                    <div className="relative">
                                                        <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 font-bold text-sm">×</span>
                                                        <input
                                                            type="number"
                                                            min="1"
                                                            max="10"
                                                            value={configValues.max_withdrawals_per_day}
                                                            onChange={e => setConfigValues(v => ({ ...v, max_withdrawals_per_day: e.target.value }))}
                                                            className="w-full pl-10 pr-4 py-3 border-2 border-orange-200 rounded-xl bg-white focus:border-orange-500 focus:ring-2 focus:ring-orange-100 transition-all font-bold text-gray-900"
                                                            placeholder="1"
                                                        />
                                                    </div>
                                                    <p className="text-xs text-gray-500 mt-1">Default: 1 kali/hari. Reset setiap tengah malam WIB.</p>
                                                </div>
                                            </div>
                                            <div className="mt-4 p-4 bg-white rounded-xl border border-orange-100 flex items-start gap-3">
                                                <svg className="w-5 h-5 text-orange-500 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                                                </svg>
                                                <div>
                                                    <p className="text-sm font-bold text-gray-800">Batas Frekuensi Penarikan</p>
                                                    <p className="text-xs text-gray-500 mt-0.5">Jumlah maksimal penarikan per hari dapat dikonfigurasi di atas. Counter reset setiap tengah malam WIB.</p>
                                                </div>
                                            </div>
                                        </div>
                                    </>
                                )}
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

                            <div className="space-y-2 max-h-40 overflow-y-auto pr-2 custom-scrollbar">
                                {Array.isArray(productLeads) && productLeads.length > 0 ? (
                                    productLeads.map((lead: any) => (
                                        <button
                                            key={lead?.id || Math.random()}
                                            onClick={() => {
                                                setSelectedLeadId(lead?.id);
                                                setSelectedMartClientId('');
                                            }}
                                            className={`w-full text-left p-4 rounded-xl border-2 transition-all ${selectedLeadId === lead?.id
                                                ? 'border-blue-500 bg-blue-50'
                                                : 'border-gray-100 hover:border-gray-200 bg-gray-50'
                                                }`}
                                        >
                                            <div className="flex justify-between items-start">
                                                <div>
                                                    <p className="font-bold text-gray-900">{lead?.visitor_name?.String || (typeof lead?.visitor_name === 'string' ? lead.visitor_name : 'Unknown')}</p>
                                                    <p className="text-sm text-gray-500">{lead?.visitor_phone?.String || (typeof lead?.visitor_phone === 'string' ? lead.visitor_phone : 'No phone')}</p>
                                                </div>
                                                <div className="text-right">
                                                    <p className="text-xs font-medium text-blue-600">Ref: {lead?.referral_code || '-'}</p>
                                                    <p className="text-xs text-gray-400">{lead?.reseller_name || '-'}</p>
                                                </div>
                                            </div>
                                        </button>
                                    ))
                                ) : (
                                    <div className="text-center py-4 bg-gray-50 rounded-xl border border-dashed border-gray-300">
                                        <p className="text-gray-500 text-sm">Tidak ada lead untuk produk ini.</p>
                                    </div>
                                )}
                            </div>

                            <label className="block text-sm font-medium text-gray-700 mt-4">Atau Pilih User Mart (Gostar Mart)</label>
                            <p className="text-xs text-gray-500 mb-2">Pilih user dari aplikasi Gostar Mart yang membeli produk ini.</p>

                            <div className="flex gap-2 mb-3">
                                <input
                                    type="text"
                                    placeholder="Cari nama, email, atau telepon..."
                                    className="flex-1 px-4 py-2 border-2 border-gray-200 rounded-xl focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all text-sm"
                                    value={clientSearchQuery}
                                    onChange={(e) => setClientSearchQuery(e.target.value)}
                                    onKeyPress={(e) => {
                                        if (e.key === 'Enter') {
                                            loadMartClients(clientSearchQuery);
                                        }
                                    }}
                                />
                                <button
                                    onClick={() => loadMartClients(clientSearchQuery)}
                                    className="px-4 py-2 bg-blue-600 text-white rounded-xl hover:bg-blue-700 transition-colors text-sm font-bold"
                                >
                                    Cari
                                </button>
                            </div>

                            <div className="space-y-2 max-h-40 overflow-y-auto pr-2 custom-scrollbar">
                                {Array.isArray(martClients) && martClients.length > 0 ? (
                                    martClients.map((martClient: any) => {
                                        if (!martClient) return null;
                                        return (
                                            <button
                                                key={martClient.id || Math.random()}
                                                onClick={() => {
                                                    setSelectedMartClientId(martClient.id);
                                                    setSelectedLeadId('');
                                                }}
                                                className={`w-full text-left p-4 rounded-xl border-2 transition-all ${selectedMartClientId === martClient.id
                                                    ? 'border-blue-500 bg-blue-50'
                                                    : 'border-gray-100 hover:border-gray-200 bg-gray-50'
                                                    }`}
                                            >
                                                <div className="flex justify-between items-start">
                                                    <div>
                                                        <p className="font-bold text-gray-900">{martClient.name?.String || (typeof martClient.name === 'string' ? martClient.name : 'Unknown')}</p>
                                                        <p className="text-sm text-gray-500">{martClient.email || 'No email'}</p>
                                                    </div>
                                                    <div className="text-right">
                                                        <p className="text-xs font-medium text-blue-600">Ref: {martClient.referral_code_used?.String || (typeof martClient.referral_code_used === 'string' ? martClient.referral_code_used : '-')}</p>
                                                    </div>
                                                </div>
                                            </button>
                                        );
                                    })
                                ) : (
                                    <div className="text-center py-4 bg-gray-50 rounded-xl border border-dashed border-gray-300">
                                        <p className="text-gray-500 text-sm">Tidak ada user mart terdaftar.</p>
                                    </div>
                                )}
                            </div>

                            <div className="mt-4">
                                <button
                                    onClick={() => {
                                        setSelectedLeadId('');
                                        setSelectedMartClientId('');
                                    }}
                                    className={`w-full text-left p-4 rounded-xl border-2 transition-all ${selectedLeadId === '' && selectedMartClientId === ''
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
        </ErrorBoundary>
    );
};

export default AdminDashboard;
