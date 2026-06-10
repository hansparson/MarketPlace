import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
    ShoppingBagIcon,
    ArrowRightOnRectangleIcon,
    LinkIcon,
    ClipboardDocumentCheckIcon,
    HomeIcon,
    BanknotesIcon,
    ChartBarIcon,
    ShareIcon,
    XMarkIcon,
    ChatBubbleLeftRightIcon,
    PhotoIcon,
    ArrowPathIcon
} from '@heroicons/react/24/outline';
import client from '../../api/client';
import { getImageUrl } from '../../utils/image';

const ClientDashboard = () => {
    const navigate = useNavigate();
    const [products, setProducts] = useState<any[]>([]);
    const [stats, setStats] = useState<any>({ total_leads: 0, active_products: 0, total_commission: 0, total_clicks: 0, total_paid: 0, available_balance: 0, recent_activities: [] });
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [copiedId, setCopiedId] = useState<string | null>(null);
    const [showShareModal, setShowShareModal] = useState(false);
    const [selectedProductForShare, setSelectedProductForShare] = useState<any>(null);

    // Payout relates
    const [payouts, setPayouts] = useState<any[]>([]);
    const [activeTab, setActiveTab] = useState<'products' | 'payouts'>('products');
    const [selectedProofUrl, setSelectedProofUrl] = useState<string | null>(null);

    useEffect(() => {
        const token = localStorage.getItem('token');
        const role = localStorage.getItem('role');

        if (!token || (role !== 'RESELLER' && role !== 'MEMBER' && role !== 'CLIENT')) {
            navigate('/login');
            return;
        }

        loadProducts();
        loadStats();
        loadPayouts();

        const interval = setInterval(() => {
            loadStats();
        }, 8000);

        return () => clearInterval(interval);
    }, []);

    const loadPayouts = async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await client.get('/client/payouts', {
                headers: { Authorization: `Bearer ${token}` }
            });
            if (res.data && res.data.message_data) {
                setPayouts(res.data.message_data);
            }
        } catch (err) {
            console.error('Failed to load payouts', err);
        }
    };

    const loadStats = async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await client.get('/client/stats', {
                headers: { Authorization: `Bearer ${token}` }
            });
            if (res.data && res.data.message_data) {
                setStats(res.data.message_data);

                // Save referral_code from stats if present
                if (res.data.message_data.referral_code) {
                    localStorage.setItem('referral_code', res.data.message_data.referral_code);
                }
            }
        } catch (err) {
            console.error('Failed to load stats', err);
        }
    };

    const loadProducts = async () => {
        setLoading(true);
        try {
            const res = await client.get('/products');
            if (res.data && res.data.message_data) {
                setProducts(res.data.message_data);
            }
        } catch (err) {
            console.error('Failed to load products', err);
        } finally {
            setLoading(false);
        }
    };

    const handleLogout = () => {
        localStorage.removeItem('token');
        localStorage.removeItem('role');
        localStorage.removeItem('referral_code');
        navigate('/');
    };

    const handleShareClick = (product: any) => {
        setSelectedProductForShare(product);
        setShowShareModal(true);
    };

    const formatPrice = (price: number) => {
        return new Intl.NumberFormat('id-ID', {
            style: 'currency',
            currency: 'IDR',
            minimumFractionDigits: 0
        }).format(price);
    };

    return (
        <div className="min-h-screen bg-[#F8FAFC]">
            {/* Nav & Sidebar can go here if needed, but keeping it simple for now */}
            <header className="bg-white border-b border-gray-100 sticky top-0 z-40">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="flex justify-between items-center h-20">
                        <div className="flex items-center gap-3">
                            <div className="w-10 h-10 bg-blue-600 rounded-2xl flex items-center justify-center shadow-lg shadow-blue-200">
                                <HomeIcon className="w-6 h-6 text-white" />
                            </div>
                            <div>
                                <h1 className="text-xl font-black text-gray-900 tracking-tight">GOSTAR <span className="text-blue-600">MART</span></h1>
                                <p className="text-[10px] font-bold text-blue-600 uppercase tracking-[0.2em] leading-none">{localStorage.getItem('role')} Panel</p>
                            </div>
                        </div>

                        <div className="flex items-center gap-3">
                            <button
                                onClick={() => navigate('/')}
                                className="flex items-center gap-2 px-4 py-2 text-sm font-bold text-blue-600 hover:bg-blue-50 rounded-xl transition-all"
                            >
                                <HomeIcon className="w-5 h-5" />
                                <span className="hidden sm:inline">Home Page</span>
                            </button>
                            <button
                                onClick={handleLogout}
                                className="flex items-center gap-2 px-4 py-2 text-sm font-bold text-red-600 hover:bg-red-50 rounded-xl transition-all"
                            >
                                <ArrowRightOnRectangleIcon className="w-5 h-5" />
                                <span className="hidden sm:inline">Logout</span>
                            </button>
                        </div>
                    </div>
                </div>
            </header>

            <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                {/* Stats Grid */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-10">
                    <div className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100">
                        <div className="flex justify-between items-start mb-4">
                            <div className="p-3 bg-blue-50 rounded-2xl">
                                <BanknotesIcon className="w-6 h-6 text-blue-600" />
                            </div>
                        </div>
                        <h3 className="text-2xl font-black text-gray-900 mb-1">{formatPrice(stats.total_commission || 0)}</h3>
                        <p className="text-xs font-bold text-gray-400 uppercase tracking-widest">Total Komisi</p>
                    </div>

                    <div className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100 font-bold">
                        <div className="flex justify-between items-start mb-4">
                            <div className="p-3 bg-red-50 rounded-2xl">
                                <BanknotesIcon className="w-6 h-6 text-red-600" />
                            </div>
                        </div>
                        <h3 className="text-2xl font-black text-gray-900 mb-1">{formatPrice(stats.total_paid || 0)}</h3>
                        <p className="text-xs font-bold text-gray-400 uppercase tracking-widest">Sudah Cair (Rembers)</p>
                    </div>

                    <div className="bg-blue-600 rounded-3xl p-6 shadow-lg shadow-blue-100 text-white">
                        <div className="flex justify-between items-start mb-4">
                            <div className="p-3 bg-white/20 rounded-2xl">
                                <BanknotesIcon className="w-6 h-6 text-white" />
                            </div>
                        </div>
                        <h3 className="text-2xl font-black mb-1">{formatPrice(stats.available_balance || (stats.total_commission - stats.total_paid) || 0)}</h3>
                        <p className="text-xs font-bold text-white/70 uppercase tracking-widest">Saldo Tersedia</p>
                    </div>

                    <div className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100">
                        <div className="flex justify-between items-start mb-4">
                            <div className="p-3 bg-purple-50 rounded-2xl">
                                <ChartBarIcon className="w-6 h-6 text-purple-600" />
                            </div>
                        </div>
                        <h3 className="text-2xl font-black text-gray-900 mb-1">{stats.total_clicks || 0}</h3>
                        <p className="text-xs font-bold text-gray-400 uppercase tracking-widest">Total Clicks</p>
                    </div>
                </div>

                {/* Tabs */}
                <div className="flex gap-2 bg-gray-200/50 p-1.5 rounded-[22px] mb-8 w-fit border border-gray-100">
                    <button
                        onClick={() => setActiveTab('products')}
                        className={`px-8 py-3 rounded-[18px] text-sm font-black transition-all ${activeTab === 'products' ? 'bg-white text-blue-600 shadow-md shadow-gray-200/50' : 'text-gray-500 hover:text-gray-700'}`}
                    >
                        Etalase Produk
                    </button>
                    <button
                        onClick={() => setActiveTab('payouts')}
                        className={`px-8 py-3 rounded-[18px] text-sm font-black transition-all ${activeTab === 'payouts' ? 'bg-white text-blue-600 shadow-md shadow-gray-200/50' : 'text-gray-500 hover:text-gray-700'}`}
                    >
                        Riwayat Komisi
                    </button>
                </div>

                {activeTab === 'products' ? (
                    <div className="space-y-8">
                        {/* Leads Section - NEW */}
                        <div className="bg-white p-8 rounded-[32px] shadow-sm border border-gray-100">
                            <div className="flex items-center justify-between mb-6">
                                <div>
                                    <h2 className="text-xl font-black text-gray-900">Calon Pembeli (Leads)</h2>
                                    <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mt-1">Orang yang mengklik link Anda dan mengisi data</p>
                                </div>
                                <div className="px-4 py-2 bg-blue-50 text-blue-600 rounded-xl text-xs font-black">
                                    {stats.recent_activities?.filter((a: any) => a.activity_type === 'LEAD').length || 0} LEADS
                                </div>
                            </div>

                            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                                {stats.recent_activities?.filter((a: any) => a.activity_type === 'LEAD').map((lead: any, idx: number) => (
                                    <div key={idx} className="p-5 bg-gray-50 rounded-3xl border border-gray-100 hover:border-blue-200 transition-all group">
                                        <div className="flex justify-between items-start mb-3">
                                            <div>
                                                <p className="font-black text-gray-900">{lead.visitor_name}</p>
                                                <p className="text-xs text-gray-500 font-bold">{lead.visitor_phone}</p>
                                            </div>
                                            <a 
                                                href={`https://wa.me/${lead.visitor_phone.replace(/\D/g, '').startsWith('0') ? '62' + lead.visitor_phone.replace(/\D/g, '').slice(1) : lead.visitor_phone.replace(/\D/g, '')}`}
                                                target="_blank"
                                                rel="noreferrer"
                                                className="p-2 bg-green-500 text-white rounded-xl shadow-lg shadow-green-100 hover:scale-110 transition-transform"
                                            >
                                                <ChatBubbleLeftRightIcon className="w-4 h-4" />
                                            </a>
                                        </div>
                                        <div className="pt-3 border-t border-gray-200/50">
                                            <p className="text-[10px] font-black text-blue-400 uppercase tracking-widest mb-1">Tertarik Produk:</p>
                                            <p className="text-xs font-bold text-gray-700 line-clamp-1">{lead.product_title}</p>
                                        </div>
                                    </div>
                                ))}
                                {(!stats.recent_activities || stats.recent_activities.filter((a: any) => a.activity_type === 'LEAD').length === 0) && (
                                    <div className="col-span-full py-10 text-center bg-gray-50/50 rounded-3xl border border-dashed border-gray-200">
                                        <p className="text-sm font-bold text-gray-400">Belum ada calon pembeli yang terdaftar.</p>
                                    </div>
                                )}
                            </div>
                        </div>

                        {/* Search */}
                        <div className="bg-white p-4 rounded-3xl shadow-sm border border-gray-100">
                            <div className="relative">
                                <input
                                    type="text"
                                    placeholder="Cari properti idaman Anda..."
                                    className="w-full pl-12 pr-4 py-4 bg-gray-50 border-none rounded-2xl text-gray-900 font-medium focus:ring-2 focus:ring-blue-500 transition-all placeholder:text-gray-400"
                                    value={searchTerm}
                                    onChange={(e) => setSearchTerm(e.target.value)}
                                />
                                <ShoppingBagIcon className="w-6 h-6 text-gray-400 absolute left-4 top-1/2 -translate-y-1/2" />
                            </div>
                        </div>

                        {/* Product Grid */}
                        {loading ? (
                            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                                {[1, 2, 3, 4].map((i) => (
                                    <div key={i} className="bg-gray-200 aspect-[4/3] rounded-3xl animate-pulse"></div>
                                ))}
                            </div>
                        ) : (
                            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                                {products
                                    .filter(p => p.status === 'ACTIVE' && (p.title.toLowerCase().includes(searchTerm.toLowerCase()) || p.description.toLowerCase().includes(searchTerm.toLowerCase())))
                                    .map((product) => (
                                        <div key={product.id} className="bg-white rounded-[32px] overflow-hidden shadow-sm border border-gray-100 hover:shadow-xl hover:shadow-blue-500/5 transition-all duration-500 group">
                                            <div className="aspect-[4/3] relative overflow-hidden">
                                                <img
                                                    src={getImageUrl(product.thumbnail_url)}
                                                    alt={product.title}
                                                    className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700"
                                                />
                                                <div className="absolute top-4 right-4 bg-white/90 backdrop-blur-md px-3 py-1.5 rounded-2xl text-[10px] font-black text-blue-600 uppercase tracking-widest border border-white/50 shadow-sm">
                                                    {product.category_name || 'Premium'}
                                                </div>
                                            </div>

                                            <div className="p-6">
                                                <h3 className="text-lg font-black text-gray-900 mb-1 line-clamp-1 group-hover:text-blue-600 transition-colors">{product.title}</h3>
                                                <p className="text-xs text-gray-400 font-bold mb-4 flex items-center gap-1">
                                                    <span className="w-1.5 h-1.5 bg-green-500 rounded-full"></span>
                                                    {formatPrice(product.price)}
                                                </p>

                                                <div className="bg-blue-50 rounded-2xl p-4 mb-5 border border-blue-100/50">
                                                    <p className="text-[10px] font-black text-blue-400 uppercase tracking-widest mb-1">Potensi Komisi</p>
                                                    <p className="text-xl font-black text-blue-700">
                                                        {localStorage.getItem('role') === 'MEMBER'
                                                            ? formatPrice(product.member_commission_amount || 0)
                                                            : formatPrice(product.reseller_commission_amount || 0)
                                                        }
                                                    </p>
                                                </div>

                                                <button
                                                    onClick={() => handleShareClick(product)}
                                                    className="w-full py-4 bg-gray-900 text-white rounded-2xl font-bold flex items-center justify-center gap-2 hover:bg-blue-600 active:scale-95 transition-all shadow-lg shadow-gray-200"
                                                >
                                                    <ShareIcon className="w-5 h-5" />
                                                    Dapatkan Link
                                                </button>
                                            </div>
                                        </div>
                                    ))}
                            </div>
                        )}
                    </div>
                ) : (
                    <div className="bg-white rounded-[32px] shadow-sm border border-gray-100 overflow-hidden">
                        <div className="p-8 border-b border-gray-50 flex items-center justify-between bg-gray-50/30">
                            <div>
                                <h2 className="text-xl font-black text-gray-900">Riwayat Pencairan Komisi</h2>
                                <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mt-1">Daftar semua komisi yang telah dibayarkan</p>
                            </div>
                            <button onClick={loadPayouts} className="p-3 bg-white text-gray-400 hover:text-blue-600 rounded-2xl transition-all shadow-sm active:scale-90">
                                <ArrowPathIcon className="w-5 h-5" />
                            </button>
                        </div>

                        <div className="overflow-x-auto">
                            <table className="w-full text-left">
                                <thead className="bg-[#F8FAFC]">
                                    <tr>
                                        <th className="px-8 py-5 text-[10px] font-black text-gray-400 uppercase tracking-[0.2em]">Tanggal</th>
                                        <th className="px-8 py-5 text-[10px] font-black text-gray-400 uppercase tracking-[0.2em]">Nominal</th>
                                        <th className="px-8 py-5 text-[10px] font-black text-gray-400 uppercase tracking-[0.2em]">Bukti Transfer</th>
                                        <th className="px-8 py-5 text-[10px] font-black text-gray-400 uppercase tracking-[0.2em]">Keterangan</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-gray-50">
                                    {payouts.length === 0 ? (
                                        <tr>
                                            <td colSpan={4} className="px-8 py-20 text-center">
                                                <div className="w-16 h-16 bg-gray-100 rounded-3xl flex items-center justify-center mx-auto mb-4">
                                                    <BanknotesIcon className="w-8 h-8 text-gray-300" />
                                                </div>
                                                <p className="text-gray-400 font-bold">Belum ada riwayat pencairan.</p>
                                            </td>
                                        </tr>
                                    ) : (
                                        payouts.map((p) => (
                                            <tr key={p.id} className="hover:bg-gray-50/50 transition-colors group">
                                                <td className="px-8 py-5 whitespace-nowrap">
                                                    <p className="text-sm font-bold text-gray-600">{new Date(p.created_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })}</p>
                                                </td>
                                                <td className="px-8 py-5 whitespace-nowrap">
                                                    <p className="text-base font-black text-blue-600">{formatPrice(p.amount)}</p>
                                                </td>
                                                <td className="px-8 py-5 whitespace-nowrap">
                                                    <button
                                                        onClick={() => setSelectedProofUrl(getImageUrl(p.proof_object_key))}
                                                        className="flex items-center gap-2 px-4 py-2 bg-blue-50 text-blue-600 rounded-xl text-xs font-black hover:bg-blue-600 hover:text-white transition-all"
                                                    >
                                                        <PhotoIcon className="w-4 h-4" />
                                                        LIHAT BUKTI
                                                    </button>
                                                </td>
                                                <td className="px-8 py-5">
                                                    <p className="text-xs font-medium text-gray-500 italic">{p.notes?.String || '-'}</p>
                                                </td>
                                            </tr>
                                        ))
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </div>
                )}
            </main>

            {/* Share Modal */}
            {showShareModal && selectedProductForShare && (
                <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
                    <div className="bg-white rounded-[40px] shadow-2xl max-w-sm w-full overflow-hidden animate-in fade-in zoom-in duration-300">
                        <div className="p-8 border-b border-gray-50 flex justify-between items-center bg-gray-50/30">
                            <div>
                                <h3 className="text-xl font-black text-gray-900 tracking-tight">Bagikan Keuntungan</h3>
                                <p className="text-xs font-bold text-blue-600 uppercase tracking-widest mt-0.5">Mulai jualan sekarang</p>
                            </div>
                            <button onClick={() => setShowShareModal(false)} className="p-3 bg-white hover:bg-gray-50 rounded-2xl transition-all shadow-sm active:scale-90">
                                <XMarkIcon className="w-6 h-6 text-gray-400" />
                            </button>
                        </div>
                        <div className="p-8">
                            <div className="grid grid-cols-2 gap-4 mb-8">
                                <button
                                    onClick={() => {
                                        const refCode = localStorage.getItem('referral_code');
                                        const url = `${window.location.origin}/products/${selectedProductForShare.id}${refCode ? `?ref=${refCode}` : ''}`;
                                        const text = encodeURIComponent(`Halo! Saya merekomendasikan properti ini: \n\n${selectedProductForShare.title}\n\nCek selengkapnya di sini: ${url}`);
                                        window.open(`https://wa.me/?text=${text}`, '_blank');
                                    }}
                                    className="flex flex-col items-center gap-3 p-6 rounded-[32px] bg-green-50 hover:bg-green-100 transition-all group"
                                >
                                    <div className="w-14 h-14 bg-green-500 rounded-2xl flex items-center justify-center text-white shadow-lg shadow-green-200 group-hover:scale-110 transition-transform">
                                        <ChatBubbleLeftRightIcon className="w-8 h-8" />
                                    </div>
                                    <span className="text-xs font-black text-green-700 uppercase tracking-widest">WhatsApp</span>
                                </button>

                                <button
                                    onClick={() => {
                                        const refCode = localStorage.getItem('referral_code');
                                        const url = `${window.location.origin}/products/${selectedProductForShare.id}${refCode ? `?ref=${refCode}` : ''}`;
                                        navigator.clipboard.writeText(url);
                                        setCopiedId(selectedProductForShare.id);
                                        setTimeout(() => {
                                            setCopiedId(null);
                                            setShowShareModal(false);
                                        }, 1500);
                                    }}
                                    className="flex flex-col items-center gap-3 p-6 rounded-[32px] bg-blue-50 hover:bg-blue-100 transition-all group"
                                >
                                    <div className={`w-14 h-14 rounded-2xl flex items-center justify-center text-white shadow-lg transition-all group-hover:scale-110 ${copiedId === selectedProductForShare.id ? 'bg-green-500' : 'bg-blue-600 shadow-blue-200'}`}>
                                        {copiedId === selectedProductForShare.id ? <ClipboardDocumentCheckIcon className="w-8 h-8" /> : <LinkIcon className="w-8 h-8" />}
                                    </div>
                                    <span className={`text-xs font-black uppercase tracking-widest ${copiedId === selectedProductForShare.id ? 'text-green-700' : 'text-blue-700'}`}>
                                        {copiedId === selectedProductForShare.id ? 'Copied!' : 'Salin Link'}
                                    </span>
                                </button>
                            </div>
                            <div className="bg-gray-50 rounded-2xl p-4 border border-gray-100">
                                <p className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1">Nama Produk</p>
                                <p className="text-sm font-bold text-gray-700 line-clamp-1">{selectedProductForShare.title}</p>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* Proof Lightbox */}
            {selectedProofUrl && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/95 p-4" onClick={() => setSelectedProofUrl(null)}>
                    <div className="relative max-w-4xl w-full">
                        <button
                            className="absolute -top-14 right-0 text-white hover:text-gray-300 flex items-center gap-2 font-black p-2"
                            onClick={() => setSelectedProofUrl(null)}
                        >
                            <XMarkIcon className="w-8 h-8" />
                            TUTUP
                        </button>
                        <img
                            src={selectedProofUrl}
                            alt="Bukti Transfer"
                            className="w-full h-auto rounded-[32px] shadow-2xl"
                            onClick={(e) => e.stopPropagation()}
                        />
                    </div>
                </div>
            )}
        </div>
    );
};

export default ClientDashboard;
