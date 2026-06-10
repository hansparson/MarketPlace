import { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import {
    ArrowLeftIcon,
    UserCircleIcon,
    EnvelopeIcon,
    PhoneIcon,
    KeyIcon,
    CalendarIcon,
    ChartBarIcon,
    BanknotesIcon,
    PhotoIcon,
    CheckCircleIcon,
    XMarkIcon,
    FingerPrintIcon,
    AtSymbolIcon
} from '@heroicons/react/24/outline';
import client from '../../api/client';
import { formatRelativeTime } from '../../utils/date';
import { getImageUrl } from '../../utils/image';

const EditReseller = () => {
    const navigate = useNavigate();
    const { id } = useParams();
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [reseller, setReseller] = useState<any>(null);
    const [stats, setStats] = useState<any>(null);
    const [sales, setSales] = useState<any[]>([]);
    const [formData, setFormData] = useState({
        name: '',
        email: '',
        phone: '',
        password: '',
        username: '',
        nik: '',
        status: 'ACTIVE'
    });

    // Payout relates
    const [payouts, setPayouts] = useState<any[]>([]);
    const [isPayoutModalOpen, setIsPayoutModalOpen] = useState(false);
    const [payoutSaving, setPayoutSaving] = useState(false);
    const [payoutForm, setPayoutForm] = useState({
        amount: '',
        notes: '',
        proof: null as File | null
    });
    const [selectedProofUrl, setSelectedProofUrl] = useState<string | null>(null);

    useEffect(() => {
        const token = localStorage.getItem('token');
        const role = localStorage.getItem('role');

        if (!token || (role !== 'SUPER_ADMIN' && role !== 'ADMIN')) {
            navigate('/auth/login/admin');
            return;
        }

        loadReseller();
        loadPayouts();
    }, [id]);

    const loadPayouts = async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await client.get('/admin/payouts', {
                headers: { Authorization: `Bearer ${token}` }
            });
            if (res.data && res.data.message_data) {
                // Filter payouts for this reseller
                const filtered = res.data.message_data.filter((p: any) => p.user_id === id && p.user_type === 'RESELLER');
                setPayouts(filtered);
            }
        } catch (err) {
            console.error('Failed to load payouts', err);
        }
    };

    const loadReseller = async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await client.get(`/admin/resellers/${id}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            if (res.data && res.data.message_data) {
                const resellerData = res.data.message_data.reseller || res.data.message_data;
                const statsData = res.data.message_data.stats || null;

                setReseller(resellerData);
                setStats(statsData);
                setSales(res.data.message_data.sales || []);
                setFormData({
                    name: resellerData.name || '',
                    email: resellerData.email?.String || '',
                    phone: resellerData.phone || '',
                    password: '',
                    username: resellerData.username?.String || '',
                    nik: resellerData.nik?.String || '',
                    status: resellerData.status || 'ACTIVE'
                });
            }
        } catch (err) {
            console.error('Failed to load reseller', err);
            alert('Failed to load reseller data');
        } finally {
            setLoading(false);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setSaving(true);

        try {
            const token = localStorage.getItem('token');
            const updateData: any = {
                name: formData.name,
                phone: formData.phone,
                username: formData.username,
                nik: formData.nik,
                status: formData.status
            };

            // Only include email if it's changed
            if (formData.email && formData.email !== reseller.email?.String) {
                updateData.email = formData.email;
            }

            // Only include password if it's provided
            if (formData.password) {
                updateData.password = formData.password;
            }

            await client.put(`/admin/resellers/${id}`, updateData, {
                headers: { Authorization: `Bearer ${token}` }
            });

            alert('Reseller updated successfully!');
            navigate('/admin/dashboard');
        } catch (err: any) {
            console.error('Failed to update reseller', err);
            alert(err.response?.data?.message || 'Failed to update reseller');
        } finally {
            setSaving(false);
        }
    };

    const handleStatusUpdate = async (newStatus: string) => {
        setSaving(true);
        try {
            const token = localStorage.getItem('token');
            await client.put(`/admin/resellers/${id}`, {
                name: formData.name,
                phone: formData.phone,
                email: formData.email,
                username: formData.username,
                nik: formData.nik,
                status: newStatus
            }, {
                headers: { Authorization: `Bearer ${token}` }
            });
            alert(`Reseller status updated to ${newStatus}`);
            loadReseller();
        } catch (err: any) {
            alert(err.response?.data?.message || 'Failed to update status');
        } finally {
            setSaving(false);
        }
    };

    const handlePayoutSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!payoutForm.amount || !payoutForm.proof) {
            alert('Please fill amount and upload proof');
            return;
        }

        const amount = parseInt(payoutForm.amount);
        if (amount > (stats?.available_balance || 0)) {
            alert('Amount exceeds available balance');
            return;
        }

        setPayoutSaving(true);
        try {
            const token = localStorage.getItem('token');
            const formData = new FormData();
            formData.append('reseller_id', id!);
            formData.append('amount', payoutForm.amount);
            formData.append('notes', payoutForm.notes);
            formData.append('proof', payoutForm.proof);

            await client.post('/admin/payouts', formData, {
                headers: {
                    'Content-Type': 'multipart/form-data',
                    Authorization: `Bearer ${token}`
                }
            });

            alert('Payout recorded successfully!');
            setIsPayoutModalOpen(false);
            setPayoutForm({ amount: '', notes: '', proof: null });
            loadReseller(); // Refresh balance
            loadPayouts(); // Refresh history
        } catch (err: any) {
            console.error('Failed to create payout', err);
            alert(err.response?.data?.message_data || 'Failed to create payout');
        } finally {
            setPayoutSaving(false);
        }
    };

    const formatPrice = (price: number) => {
        return new Intl.NumberFormat('id-ID', {
            style: 'currency',
            currency: 'IDR',
            minimumFractionDigits: 0
        }).format(price);
    };

    if (loading) {
        return (
            <div className="min-h-screen bg-gray-50 flex items-center justify-center">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
            </div>
        );
    }

    if (!reseller) {
        return (
            <div className="min-h-screen bg-gray-50 flex items-center justify-center">
                <div className="text-center">
                    <p className="text-gray-500 mb-4">Reseller not found</p>
                    <button
                        onClick={() => navigate('/admin/dashboard')}
                        className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                    >
                        Back to Dashboard
                    </button>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
            {/* Header */}
            <header className="bg-white shadow-sm border-b border-gray-200 sticky top-0 z-30">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
                    <div className="flex items-center justify-between">
                        <button
                            onClick={() => navigate('/admin/dashboard')}
                            className="flex items-center gap-2 text-gray-600 hover:text-gray-900 transition-colors"
                        >
                            <ArrowLeftIcon className="w-5 h-5" />
                            <span className="font-medium">Back to Dashboard</span>
                        </button>
                        <h1 className="text-xl font-bold text-gray-900">Edit Reseller</h1>
                    </div>
                </div>
            </header>

            <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    {/* Left Column - Stats */}
                    <div className="lg:col-span-1 space-y-6">
                        {/* Reseller Info Card */}
                        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
                            <div className="flex flex-col items-center text-center">
                                {reseller.profile_image?.String ? (
                                    <img
                                        src={getImageUrl(reseller.profile_image.String)}
                                        alt="Profile"
                                        className="w-24 h-24 rounded-full object-cover shadow-lg mb-4 cursor-zoom-in border-2 border-gray-100"
                                        onClick={() => setSelectedProofUrl(getImageUrl(reseller.profile_image.String))}
                                    />
                                ) : (
                                    <div className="w-24 h-24 bg-gradient-to-br from-green-400 to-green-600 rounded-full flex items-center justify-center text-white font-black text-3xl uppercase shadow-lg mb-4">
                                        {reseller.name?.charAt(0) || '?'}
                                    </div>
                                )}
                                <h3 className="text-xl font-bold text-gray-900 mb-1">{reseller.name}</h3>
                                <div className="mt-2 flex gap-2">
                                    {reseller.status === 'ACTIVE' && <span className="px-3 py-1 bg-green-100 text-green-700 rounded-full text-[10px] font-black uppercase tracking-wider">Active</span>}
                                    {reseller.status === 'BLOCKED' && <span className="px-3 py-1 bg-red-100 text-red-700 rounded-full text-[10px] font-black uppercase tracking-wider">Blocked</span>}
                                </div>
                                <p className="text-sm text-gray-500 mt-3">{reseller.email?.String || 'No email'}</p>
                                <p className="text-sm text-gray-600 font-medium">{reseller.phone}</p>
                                <div className="mt-4 flex flex-col items-center gap-2">
                                    {reseller.member_name?.String && (
                                        <div className="flex items-center gap-1.5 px-3 py-1 bg-indigo-50 text-indigo-600 rounded-full text-[10px] font-black uppercase tracking-wider border border-indigo-100">
                                            <UserCircleIcon className="w-3.5 h-3.5" />
                                            Leader: {reseller.member_name.String}
                                        </div>
                                    )}
                                    <div className="flex items-center gap-2 text-xs text-gray-500">
                                        <CalendarIcon className="w-4 h-4" />
                                        Joined {formatRelativeTime(reseller.created_at)}
                                    </div>
                                </div>
                                <div className="mt-6 flex flex-col w-full gap-3">
                                    {reseller.status !== 'ACTIVE' && (
                                        <button
                                            onClick={() => handleStatusUpdate('ACTIVE')}
                                            disabled={saving}
                                            className="w-full py-3 bg-green-600 text-white rounded-xl font-bold text-sm hover:bg-green-700 transition-all shadow-md shadow-green-100 disabled:opacity-50"
                                        >
                                            {saving ? 'Processing...' : 'Activate Reseller'}
                                        </button>
                                    )}
                                    {reseller.status !== 'BLOCKED' && (
                                        <button
                                            onClick={() => handleStatusUpdate('BLOCKED')}
                                            disabled={saving}
                                            className="w-full py-3 bg-red-100 text-red-600 rounded-xl font-bold text-sm hover:bg-red-200 transition-all disabled:opacity-50"
                                        >
                                            {saving ? 'Processing...' : 'Block Reseller'}
                                        </button>
                                    )}
                                </div>
                            </div>
                        </div>

                        {/* Stats Cards */}
                        {stats && (
                            <>
                                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
                                    <div className="flex items-center gap-3 mb-3">
                                        <div className="p-3 bg-green-100 rounded-xl">
                                            <BanknotesIcon className="w-6 h-6 text-green-600" />
                                        </div>
                                        <div>
                                            <p className="text-xs text-gray-500 font-bold uppercase">Total Commission</p>
                                            <p className="text-2xl font-black text-gray-900">{formatPrice(stats.total_commission || 0)}</p>
                                        </div>
                                    </div>
                                </div>

                                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
                                    <div className="flex items-center gap-3 mb-3">
                                        <div className="p-3 bg-blue-100 rounded-xl">
                                            <ChartBarIcon className="w-6 h-6 text-blue-600" />
                                        </div>
                                        <div>
                                            <p className="text-xs text-gray-500 font-bold uppercase">Total Clicks</p>
                                            <p className="text-2xl font-black text-gray-900">{stats.total_clicks || 0}</p>
                                        </div>
                                    </div>
                                </div>

                                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
                                    <div className="flex items-center gap-3 mb-3">
                                        <div className="p-3 bg-purple-100 rounded-xl">
                                            <UserCircleIcon className="w-6 h-6 text-purple-600" />
                                        </div>
                                        <div>
                                            <p className="text-xs text-gray-500 font-bold uppercase">Total Leads</p>
                                            <p className="text-2xl font-black text-gray-900">{stats.total_leads || 0}</p>
                                        </div>
                                    </div>
                                </div>

                                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
                                    <div className="flex items-center gap-3 mb-3">
                                        <div className="p-3 bg-red-100 rounded-xl">
                                            <CheckCircleIcon className="w-6 h-6 text-red-600" />
                                        </div>
                                        <div>
                                            <p className="text-xs text-gray-500 font-bold uppercase">Total Paid (Rembers)</p>
                                            <p className="text-2xl font-black text-gray-900">{formatPrice(stats.total_paid || 0)}</p>
                                        </div>
                                    </div>
                                </div>

                                <div className="bg-blue-600 rounded-2xl shadow-lg border border-blue-700 p-6 text-white">
                                    <div className="flex items-center gap-3 mb-4">
                                        <div className="p-3 bg-white/20 rounded-xl">
                                            <BanknotesIcon className="w-6 h-6 text-white" />
                                        </div>
                                        <div>
                                            <p className="text-xs text-white/70 font-bold uppercase">Available Balance</p>
                                            <p className="text-2xl font-black">{formatPrice(stats.available_balance || 0)}</p>
                                        </div>
                                    </div>
                                    <button
                                        onClick={() => setIsPayoutModalOpen(true)}
                                        disabled={stats.available_balance <= 0}
                                        className={`w-full py-3 rounded-xl font-bold flex items-center justify-center gap-2 transition-all ${stats.available_balance > 0
                                            ? 'bg-white text-blue-600 hover:bg-gray-100 active:scale-95'
                                            : 'bg-white/50 text-white/70 cursor-not-allowed'
                                            }`}
                                    >
                                        <BanknotesIcon className="w-5 h-5" />
                                        Pay Commission (Rembers)
                                    </button>
                                </div>
                            </>
                        )}
                    </div>

                    {/* Right Column - Edit Form */}
                    <div className="lg:col-span-2">
                        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 sm:p-8">
                            <h2 className="text-2xl font-bold text-gray-900 mb-6">Reseller Information</h2>
                            <form onSubmit={handleSubmit} className="space-y-6">
                                {/* Name */}
                                <div>
                                    <label className="block text-sm font-bold text-gray-700 mb-2">
                                        <div className="flex items-center gap-2">
                                            <UserCircleIcon className="w-5 h-5 text-gray-400" />
                                            Full Name
                                        </div>
                                    </label>
                                    <input
                                        type="text"
                                        required
                                        value={formData.name}
                                        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                        className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500 focus:border-transparent transition-all text-gray-900 font-medium"
                                    />
                                </div>

                                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                    {/* Username */}
                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-2">
                                            <div className="flex items-center gap-2">
                                                <AtSymbolIcon className="w-5 h-5 text-gray-400" />
                                                Username
                                            </div>
                                        </label>
                                        <input
                                            type="text"
                                            value={formData.username}
                                            onChange={(e) => setFormData({ ...formData, username: e.target.value })}
                                            className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500 focus:border-transparent transition-all"
                                        />
                                    </div>
                                    {/* NIK */}
                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-2">
                                            <div className="flex items-center gap-2">
                                                <FingerPrintIcon className="w-5 h-5 text-gray-400" />
                                                NIK (KTP Number)
                                            </div>
                                        </label>
                                        <input
                                            type="text"
                                            value={formData.nik}
                                            onChange={(e) => setFormData({ ...formData, nik: e.target.value })}
                                            className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500 focus:border-transparent transition-all"
                                        />
                                    </div>
                                </div>

                                {/* Email */}
                                <div>
                                    <label className="block text-sm font-bold text-gray-700 mb-2">
                                        <div className="flex items-center gap-2">
                                            <EnvelopeIcon className="w-5 h-5 text-gray-400" />
                                            Email Address
                                        </div>
                                    </label>
                                    <input
                                        type="email"
                                        value={formData.email}
                                        onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                                        className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500 focus:border-transparent transition-all text-gray-900 font-medium"
                                        placeholder="email@example.com"
                                    />
                                    <p className="text-xs text-gray-500 mt-1">Leave blank to keep current email</p>
                                </div>

                                {/* Phone */}
                                <div>
                                    <label className="block text-sm font-bold text-gray-700 mb-2">
                                        <div className="flex items-center gap-2">
                                            <PhoneIcon className="w-5 h-5 text-gray-400" />
                                            Phone Number
                                        </div>
                                    </label>
                                    <input
                                        type="tel"
                                        required
                                        value={formData.phone}
                                        onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                                        className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500 focus:border-transparent transition-all text-gray-900 font-medium"
                                    />
                                </div>

                                {/* Password */}
                                <div>
                                    <label className="block text-sm font-bold text-gray-700 mb-2">
                                        <div className="flex items-center gap-2">
                                            <KeyIcon className="w-5 h-5 text-gray-400" />
                                            New Password
                                        </div>
                                    </label>
                                    <input
                                        type="password"
                                        value={formData.password}
                                        onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                                        className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500 focus:border-transparent transition-all text-gray-900 font-medium"
                                        placeholder="Leave blank to keep current password"
                                    />
                                    <p className="text-xs text-gray-500 mt-1">Only fill this if you want to change the password</p>
                                </div>

                                {reseller.member_name?.String && (
                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-2">Member (Leader)</label>
                                        <div className="px-4 py-3 bg-indigo-50 border border-indigo-100 rounded-xl text-indigo-700 font-bold flex items-center justify-between">
                                            <span>{reseller.member_name.String}</span>
                                            <span className="text-[10px] bg-indigo-600 text-white px-2 py-0.5 rounded uppercase tracking-tighter">Active Leader</span>
                                        </div>
                                        <p className="text-xs text-gray-500 mt-1">This reseller is managed by the leader above</p>
                                    </div>
                                )}

                                {/* Referral Code (Read Only) */}
                                <div>
                                    <label className="block text-sm font-bold text-gray-700 mb-2">Referral Code</label>
                                    <div className="px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-gray-700 font-mono font-bold">
                                        {reseller.referral_code?.String || reseller.referral_code || 'No Code'}
                                    </div>
                                    <p className="text-xs text-gray-500 mt-1">Referral code cannot be changed</p>
                                </div>

                                {/* Identity Images */}
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-8 pt-4">
                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-3">Profile Photo</label>
                                        <div className="relative aspect-square rounded-2xl overflow-hidden border-2 border-gray-100 bg-gray-50 shadow-inner">
                                            {reseller.profile_image?.String ? (
                                                <img
                                                    src={getImageUrl(reseller.profile_image.String)}
                                                    alt="Profile"
                                                    className="w-full h-full object-cover cursor-zoom-in hover:scale-105 transition-transform"
                                                    onClick={() => setSelectedProofUrl(getImageUrl(reseller.profile_image.String))}
                                                />
                                            ) : (
                                                <div className="w-full h-full flex flex-col items-center justify-center text-gray-300">
                                                    <PhotoIcon className="w-12 h-12" />
                                                    <span className="text-[10px] font-bold mt-2 uppercase tracking-widest">No Profile Photo</span>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-3">KTP Image</label>
                                        <div className="relative aspect-[3/2] rounded-2xl overflow-hidden border-2 border-gray-100 bg-gray-50 shadow-inner">
                                            {reseller.ktp_image?.String ? (
                                                <img
                                                    src={getImageUrl(reseller.ktp_image.String)}
                                                    alt="KTP"
                                                    className="w-full h-full object-cover cursor-zoom-in hover:scale-105 transition-transform"
                                                    onClick={() => setSelectedProofUrl(getImageUrl(reseller.ktp_image.String))}
                                                />
                                            ) : (
                                                <div className="w-full h-full flex flex-col items-center justify-center text-gray-300">
                                                    <PhotoIcon className="w-12 h-12" />
                                                    <span className="text-[10px] font-bold mt-2 uppercase tracking-widest">No KTP Photo</span>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </div>

                                <div className="flex gap-4 pt-4 border-t border-gray-100">
                                    <button
                                        type="button"
                                        onClick={() => navigate('/admin/dashboard')}
                                        className="flex-1 px-6 py-3 border border-gray-300 text-gray-700 rounded-xl hover:bg-gray-50 transition-all font-bold"
                                    >
                                        Cancel
                                    </button>
                                    <button
                                        type="submit"
                                        disabled={saving}
                                        className={`flex-1 px-6 py-3 rounded-xl font-bold text-white shadow-lg transition-all ${saving
                                            ? 'bg-gray-400 cursor-not-allowed'
                                            : 'bg-blue-600 hover:bg-blue-700 active:scale-95'
                                            }`}
                                    >
                                        {saving ? 'Saving...' : 'Save Changes'}
                                    </button>
                                </div>
                            </form>
                        </div>
                        
                        {/* Sales History */}
                        <div className="mt-8 bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                            <div className="p-6 border-b border-gray-100 flex items-center justify-between">
                                <h2 className="text-xl font-bold text-gray-900">Sales History (Sold Products)</h2>
                                <span className="px-3 py-1 bg-green-100 text-green-700 rounded-full text-xs font-black uppercase tracking-wider">
                                    {sales.length} Items Sold
                                </span>
                            </div>
                            <div className="overflow-x-auto">
                                <table className="w-full">
                                    <thead className="bg-gray-50">
                                        <tr>
                                            <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Product Name</th>
                                            <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Commission</th>
                                            <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Sold Date</th>
                                            <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Status</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-gray-100">
                                        {sales.length === 0 ? (
                                            <tr>
                                                <td colSpan={4} className="px-6 py-8 text-center text-gray-500 italic">No sales recorded yet.</td>
                                            </tr>
                                        ) : (
                                            sales.map((sale) => (
                                                <tr key={sale.id}>
                                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 font-bold">
                                                        {sale.product_title}
                                                    </td>
                                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-green-600 font-black">
                                                        {formatPrice(sale.amount)}
                                                    </td>
                                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 font-medium">
                                                        {new Date(sale.created_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })}
                                                    </td>
                                                    <td className="px-6 py-4 whitespace-nowrap">
                                                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider ${
                                                            sale.status === 'PAID' ? 'bg-blue-100 text-blue-700' : 'bg-orange-100 text-orange-700'
                                                        }`}>
                                                            {sale.status}
                                                        </span>
                                                    </td>
                                                </tr>
                                            ))
                                        )}
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        {/* Payout History */}
                        <div className="mt-8 bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                            <div className="p-6 border-b border-gray-100">
                                <h2 className="text-xl font-bold text-gray-900">Payout History (Rembers)</h2>
                            </div>
                            <div className="overflow-x-auto">
                                <table className="w-full">
                                    <thead className="bg-gray-50">
                                        <tr>
                                            <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Date</th>
                                            <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Amount</th>
                                            <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Proof</th>
                                            <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Notes</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-gray-100">
                                        {payouts.length === 0 ? (
                                            <tr>
                                                <td colSpan={4} className="px-6 py-8 text-center text-gray-500">No payouts found.</td>
                                            </tr>
                                        ) : (
                                            payouts.map((p) => (
                                                <tr key={p.id}>
                                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600 font-medium">
                                                        {new Date(p.created_at).toLocaleDateString()}
                                                    </td>
                                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-blue-600 font-bold">
                                                        {formatPrice(p.amount)}
                                                    </td>
                                                    <td className="px-6 py-4 whitespace-nowrap">
                                                        <button
                                                            onClick={() => setSelectedProofUrl(getImageUrl(p.proof_object_key))}
                                                            className="flex items-center gap-1.5 px-3 py-1.5 bg-gray-100 hover:bg-gray-200 rounded-lg text-xs font-bold text-gray-700 transition-colors"
                                                        >
                                                            <PhotoIcon className="w-4 h-4" />
                                                            View Proof
                                                        </button>
                                                    </td>
                                                    <td className="px-6 py-4 text-sm text-gray-500 italic">
                                                        {p.notes?.String || '-'}
                                                    </td>
                                                </tr>
                                            ))
                                        )}
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </main>

            {/* Payout Modal */}
            {isPayoutModalOpen && (
                <div className="fixed inset-0 z-50 overflow-y-auto">
                    <div className="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:p-0">
                        <div className="fixed inset-0 transition-opacity bg-black/60 backdrop-blur-sm" onClick={() => setIsPayoutModalOpen(false)}></div>

                        <div className="relative inline-block overflow-hidden text-left align-middle transition-all transform bg-white shadow-2xl rounded-3xl sm:max-w-lg sm:w-full">
                            <div className="p-8">
                                <div className="flex items-center justify-between mb-6">
                                    <h3 className="text-2xl font-black text-gray-900">Pay Commission (Rembers)</h3>
                                    <button onClick={() => setIsPayoutModalOpen(false)} className="p-2 text-gray-400 hover:text-gray-600 transition-colors">
                                        <XMarkIcon className="w-6 h-6" />
                                    </button>
                                </div>

                                <form onSubmit={handlePayoutSubmit} className="space-y-6">
                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-2 uppercase tracking-wider">Amount to Pay (IDR)</label>
                                        <div className="relative">
                                            <div className="absolute inset-y-0 left-0 flex items-center pl-4 pointer-events-none">
                                                <span className="text-gray-500 font-bold">Rp</span>
                                            </div>
                                            <input
                                                type="number"
                                                required
                                                max={stats?.available_balance || 0}
                                                value={payoutForm.amount}
                                                onChange={(e) => setPayoutForm({ ...payoutForm, amount: e.target.value })}
                                                className="w-full pl-12 pr-4 py-4 border-2 border-gray-100 rounded-2xl focus:border-blue-500 focus:ring-0 text-xl font-bold text-gray-900 transition-all"
                                                placeholder="0"
                                            />
                                        </div>
                                        <p className="mt-2 text-sm text-gray-500 flex justify-between">
                                            <span>Maximum: <b>{formatPrice(stats?.available_balance || 0)}</b></span>
                                        </p>
                                    </div>

                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-2 uppercase tracking-wider">Proof of Transfer (Image)</label>
                                        <div className="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-200 border-dashed rounded-2xl hover:border-blue-400 transition-all cursor-pointer relative group">
                                            <input
                                                type="file"
                                                accept="image/*"
                                                required
                                                onChange={(e) => setPayoutForm({ ...payoutForm, proof: e.target.files?.[0] || null })}
                                                className="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                                            />
                                            <div className="space-y-1 text-center">
                                                <PhotoIcon className="mx-auto h-12 w-12 text-gray-400 group-hover:text-blue-500 transition-colors" />
                                                <div className="flex text-sm text-gray-600">
                                                    <span className="relative font-bold text-blue-600">
                                                        {payoutForm.proof ? payoutForm.proof.name : 'Click to upload proof'}
                                                    </span>
                                                </div>
                                                <p className="text-xs text-gray-500">PNG, JPG, GIF up to 10MB</p>
                                            </div>
                                        </div>
                                    </div>

                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-2 uppercase tracking-wider">Notes (Optional)</label>
                                        <textarea
                                            value={payoutForm.notes}
                                            onChange={(e) => setPayoutForm({ ...payoutForm, notes: e.target.value })}
                                            className="w-full px-4 py-3 border-2 border-gray-100 rounded-2xl focus:border-blue-500 focus:ring-0 text-gray-700 transition-all"
                                            rows={2}
                                            placeholder="Example: Payout for Dec 2025"
                                        />
                                    </div>

                                    <div className="flex gap-3 pt-2">
                                        <button
                                            type="button"
                                            onClick={() => setIsPayoutModalOpen(false)}
                                            className="flex-1 py-4 bg-gray-100 text-gray-600 rounded-2xl font-bold hover:bg-gray-200 transition-all"
                                        >
                                            Cancel
                                        </button>
                                        <button
                                            type="submit"
                                            disabled={payoutSaving}
                                            className={`flex-1 py-4 bg-blue-600 text-white rounded-2xl font-bold shadow-lg shadow-blue-200 hover:bg-blue-700 active:scale-95 transition-all flex items-center justify-center gap-2 ${payoutSaving ? 'opacity-50' : ''}`}
                                        >
                                            {payoutSaving ? (
                                                <>
                                                    <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                                                    Processing...
                                                </>
                                            ) : (
                                                'Confirm Payout'
                                            )}
                                        </button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* Proof Lightbox */}
            {selectedProofUrl && (
                <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/90 p-4" onClick={() => setSelectedProofUrl(null)}>
                    <div className="relative max-w-4xl w-full">
                        <button
                            className="absolute -top-12 right-0 text-white hover:text-gray-300 flex items-center gap-1 font-bold"
                            onClick={() => setSelectedProofUrl(null)}
                        >
                            <XMarkIcon className="w-6 h-6" />
                            Close
                        </button>
                        <img
                            src={selectedProofUrl}
                            alt="Transfer Proof"
                            className="w-full h-auto rounded-xl shadow-2xl cursor-default"
                            onClick={(e) => e.stopPropagation()}
                        />
                    </div>
                </div>
            )}
        </div>
    );
};

export default EditReseller;
