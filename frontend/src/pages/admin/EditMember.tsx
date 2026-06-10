import { useEffect, useState } from 'react';
import { useNavigate, useParams, Link } from 'react-router-dom';
import {
    ArrowLeftIcon,
    CalendarIcon,
    ChartBarIcon,
    BanknotesIcon,
    PhotoIcon,
    XMarkIcon,
    UserGroupIcon,
    UserIcon,
    ArrowRightIcon
} from '@heroicons/react/24/outline';
import client from '../../api/client';
import { formatRelativeTime } from '../../utils/date';
import { getImageUrl } from '../../utils/image';

const EditMember = () => {
    const navigate = useNavigate();
    const { id } = useParams();
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [activeTab, setActiveTab] = useState('info'); // 'info' or 'resellers'
    const [resellers, setResellers] = useState<any[]>([]);
    const [loadingResellers, setLoadingResellers] = useState(false);
    const [member, setMember] = useState<any>(null);
    const [stats, setStats] = useState<any>(null);
    const [sales, setSales] = useState<any[]>([]);
    const [formData, setFormData] = useState({
        name: '',
        email: '',
        phone: '',
        password: '',
        status: 'ACTIVE',
        username: '',
        nik: ''
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

    const loadResellers = async () => {
        setLoadingResellers(true);
        try {
            const token = localStorage.getItem('token');
            const res = await client.get(`/admin/members/${id}/resellers`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setResellers(res.data.message_data || []);
        } catch (err) {
            console.error('Failed to load resellers', err);
        } finally {
            setLoadingResellers(false);
        }
    };

    useEffect(() => {
        const token = localStorage.getItem('token');
        const role = localStorage.getItem('role');

        if (!token || (role !== 'SUPER_ADMIN' && role !== 'ADMIN')) {
            navigate('/auth/login/admin');
            return;
        }

        loadMember();
        loadPayouts();
        loadResellers();
    }, [id]);

    const loadPayouts = async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await client.get('/admin/payouts', {
                headers: { Authorization: `Bearer ${token}` }
            });
            if (res.data && res.data.message_data) {
                // Filter payouts for this member
                const filtered = res.data.message_data.filter((p: any) => p.user_id === id && p.user_type === 'MEMBER');
                setPayouts(filtered);
            }
        } catch (err) {
            console.error('Failed to load payouts', err);
        }
    };

    const loadMember = async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await client.get(`/admin/members/${id}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            if (res.data && res.data.message_data) {
                const memberData = res.data.message_data.member || res.data.message_data;
                const statsData = res.data.message_data.stats || null;

                setMember(memberData);
                setStats(statsData);
                setSales(res.data.message_data.sales || []);
                setFormData({
                    name: memberData.name || '',
                    email: memberData.email?.String || '',
                    phone: memberData.phone || '',
                    password: '',
                    status: memberData.status || 'ACTIVE',
                    username: memberData.username?.String || '',
                    nik: memberData.nik?.String || ''
                });
            }
        } catch (err) {
            console.error('Failed to load member', err);
            alert('Failed to load member data');
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
                status: formData.status,
                username: formData.username,
                nik: formData.nik
            };

            if (formData.email !== member.email?.String) {
                updateData.email = formData.email;
            }

            if (formData.password) {
                updateData.password = formData.password;
            }

            await client.put(`/admin/members/${id}`, updateData, {
                headers: { Authorization: `Bearer ${token}` }
            });

            alert('Member updated successfully!');
            navigate('/admin/dashboard');
        } catch (err: any) {
            console.error('Failed to update member', err);
            alert(err.response?.data?.message || 'Failed to update member');
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
            formData.append('user_id', id!);
            formData.append('user_type', 'MEMBER');
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
            loadMember(); // Refresh balance
            loadPayouts(); // Refresh history
        } catch (err: any) {
            console.error('Failed to create payout', err);
            alert(err.response?.data?.message_data || 'Failed to create payout');
        } finally {
            setPayoutSaving(false);
        }
    };

    const handleStatusUpdate = async (newStatus: string) => {
        setSaving(true);
        try {
            const token = localStorage.getItem('token');
            const updateData: any = {
                name: formData.name,
                phone: formData.phone,
                email: formData.email,
                username: formData.username,
                nik: formData.nik,
                status: newStatus
            };

            await client.put(`/admin/members/${id}`, updateData, {
                headers: { Authorization: `Bearer ${token}` }
            });

            alert(`Member status updated to ${newStatus}`);
            loadMember(); // Refresh data
        } catch (err: any) {
            console.error('Failed to update status', err);
            alert(err.response?.data?.message || 'Failed to update status');
        } finally {
            setSaving(false);
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
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
            </div>
        );
    }

    if (!member) {
        return (
            <div className="min-h-screen bg-gray-50 flex items-center justify-center">
                <div className="text-center">
                    <p className="text-gray-500 mb-4">Member not found</p>
                    <button
                        onClick={() => navigate('/admin/dashboard')}
                        className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700"
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
                        <h1 className="text-xl font-bold text-gray-900">Edit Member (Leader)</h1>
                    </div>
                </div>
            </header>

            <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    {/* Left Column - Stats */}
                    <div className="lg:col-span-1 space-y-6">
                        {/* Member Info Card */}
                        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
                            <div className="flex flex-col items-center text-center">
                                <div className="w-24 h-24 bg-gradient-to-br from-indigo-400 to-indigo-600 rounded-full flex items-center justify-center text-white font-black text-3xl uppercase shadow-lg mb-4">
                                    {member.name?.charAt(0) || '?'}
                                </div>
                                <h3 className="text-xl font-bold text-gray-900 mb-1">{member.name}</h3>
                                <div className="mt-2 flex gap-2">
                                    {member.status === 'PENDING' && <span className="px-3 py-1 bg-yellow-100 text-yellow-700 rounded-full text-[10px] font-black uppercase tracking-wider">Status: PENDING</span>}
                                    {member.status === 'ACTIVE' && <span className="px-3 py-1 bg-green-100 text-green-700 rounded-full text-[10px] font-black uppercase tracking-wider">Status: ACTIVE</span>}
                                    {member.status === 'BLOCKED' && <span className="px-3 py-1 bg-red-100 text-red-700 rounded-full text-[10px] font-black uppercase tracking-wider">Status: BLOCKED</span>}
                                </div>
                                <p className="text-sm text-gray-500 mt-3">{member.email?.String || 'No email'}</p>
                                <p className="text-sm text-gray-600 font-medium">{member.phone}</p>
                                <div className="mt-4 flex items-center gap-2 text-xs text-gray-500">
                                    <CalendarIcon className="w-4 h-4" />
                                    Joined {formatRelativeTime(member.created_at)}
                                </div>
                                
                                {member.status === 'PENDING' && (
                                    <div className="mt-6 flex flex-col w-full gap-3">
                                        <button 
                                            onClick={() => handleStatusUpdate('ACTIVE')}
                                            disabled={saving}
                                            className="w-full py-3 bg-green-600 text-white rounded-xl font-bold text-sm hover:bg-green-700 transition-all shadow-md shadow-green-100 disabled:opacity-50"
                                        >
                                            {saving ? 'Processing...' : 'Approve Member'}
                                        </button>
                                        <button 
                                            onClick={() => handleStatusUpdate('BLOCKED')}
                                            disabled={saving}
                                            className="w-full py-3 bg-red-100 text-red-600 rounded-xl font-bold text-sm hover:bg-red-200 transition-all disabled:opacity-50"
                                        >
                                            {saving ? 'Processing...' : 'Decline (Block)'}
                                        </button>
                                    </div>
                                )}

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
                                        <div className="p-3 bg-indigo-100 rounded-xl">
                                            <UserGroupIcon className="w-6 h-6 text-indigo-600" />
                                        </div>
                                        <div>
                                            <p className="text-xs text-gray-500 font-bold uppercase">Managed Resellers</p>
                                            <p className="text-2xl font-black text-gray-900">{stats.total_resellers || 0}</p>
                                        </div>
                                    </div>
                                </div>

                                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
                                    <div className="flex items-center gap-3 mb-3">
                                        <div className="p-3 bg-purple-100 rounded-xl">
                                            <ChartBarIcon className="w-6 h-6 text-purple-600" />
                                        </div>
                                        <div>
                                            <p className="text-xs text-gray-500 font-bold uppercase">Team Leads</p>
                                            <p className="text-2xl font-black text-gray-900">{stats.total_leads || 0}</p>
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

                    {/* Right Column - Tabs & Content */}
                    <div className="lg:col-span-2 space-y-6">
                        {/* Tab Switcher */}
                        <div className="flex bg-white p-1.5 rounded-2xl border border-gray-100 shadow-sm">
                            <button
                                onClick={() => setActiveTab('info')}
                                className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-xl font-bold text-sm transition-all ${activeTab === 'info'
                                        ? 'bg-indigo-600 text-white shadow-md shadow-indigo-100'
                                        : 'text-gray-500 hover:bg-gray-50'
                                    }`}
                            >
                                <UserIcon className="w-4 h-4" />
                                Member Information
                            </button>
                            <button
                                onClick={() => setActiveTab('resellers')}
                                className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-xl font-bold text-sm transition-all ${activeTab === 'resellers'
                                        ? 'bg-indigo-600 text-white shadow-md shadow-indigo-100'
                                        : 'text-gray-500 hover:bg-gray-50'
                                    }`}
                            >
                                <UserGroupIcon className="w-4 h-4" />
                                Managed Resellers
                                {resellers.length > 0 && (
                                    <span className={`px-2 py-0.5 rounded-full text-[10px] ${activeTab === 'resellers' ? 'bg-white/20 text-white' : 'bg-gray-100 text-gray-500'}`}>
                                        {resellers.length}
                                    </span>
                                )}
                            </button>
                        </div>

                        {activeTab === 'info' ? (
                            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 sm:p-8">
                                <h2 className="text-2xl font-bold text-gray-900 mb-6">Member Information</h2>

                            <form onSubmit={handleSubmit} className="space-y-6">
                                {/* Name */}
                                <div>
                                    <label className="block text-sm font-bold text-gray-700 mb-2">Full Name</label>
                                    <input
                                        type="text"
                                        required
                                        value={formData.name}
                                        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                        className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all"
                                    />
                                </div>

                                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                    {/* Username */}
                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-2">Username</label>
                                        <input
                                            type="text"
                                            value={formData.username}
                                            onChange={(e) => setFormData({ ...formData, username: e.target.value })}
                                            className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all"
                                        />
                                    </div>
                                    {/* NIK */}
                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-2">NIK (KTP Number)</label>
                                        <input
                                            type="text"
                                            value={formData.nik}
                                            onChange={(e) => setFormData({ ...formData, nik: e.target.value })}
                                            className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all"
                                        />
                                    </div>
                                </div>


                                {/* Email */}
                                <div>
                                    <label className="block text-sm font-bold text-gray-700 mb-2">Email Address</label>
                                    <input
                                        type="email"
                                        value={formData.email}
                                        onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                                        className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all"
                                    />
                                </div>

                                {/* Phone */}
                                <div>
                                    <label className="block text-sm font-bold text-gray-700 mb-2">Phone Number</label>
                                    <input
                                        type="tel"
                                        required
                                        value={formData.phone}
                                        onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                                        className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all"
                                    />
                                </div>

                                {/* Referral Code */}
                                <div>
                                    <label className="block text-sm font-bold text-gray-700 mb-2">Referral Code</label>
                                    <div className="px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-gray-700 font-mono font-bold">
                                        {member.referral_code}
                                    </div>
                                </div>

                                {/* Identity Images */}
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-8 pt-4">
                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-3">Profile Photo</label>
                                        <div className="relative aspect-square rounded-2xl overflow-hidden border-2 border-gray-100 bg-gray-50 shadow-inner group">
                                            {member.profile_image?.String ? (
                                                <img 
                                                    src={getImageUrl(member.profile_image.String)} 
                                                    alt="Profile" 
                                                    className="w-full h-full object-cover cursor-zoom-in hover:scale-105 transition-transform"
                                                    onClick={() => setSelectedProofUrl(getImageUrl(member.profile_image.String))}
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
                                        <div className="relative aspect-[3/2] rounded-2xl overflow-hidden border-2 border-gray-100 bg-gray-50 shadow-inner group">
                                            {member.ktp_image?.String ? (
                                                <img 
                                                    src={getImageUrl(member.ktp_image.String)} 
                                                    alt="KTP" 
                                                    className="w-full h-full object-cover cursor-zoom-in hover:scale-105 transition-transform"
                                                    onClick={() => setSelectedProofUrl(getImageUrl(member.ktp_image.String))}
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


                                {/* Action Buttons */}
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
                                            : 'bg-indigo-600 hover:bg-indigo-700 active:scale-95'
                                            }`}
                                    >
                                        {saving ? 'Saving...' : 'Save Changes'}
                                    </button>
                                </div>
                            </form>
                        </div>
                    ) : (
                        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 sm:p-8">
                            <div className="flex justify-between items-center mb-6">
                                <h2 className="text-2xl font-bold text-gray-900">Managed Resellers</h2>
                                <p className="text-sm text-gray-500 font-medium">{resellers.length} Resellers</p>
                            </div>

                            {loadingResellers ? (
                                <div className="py-12 flex justify-center">
                                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
                                </div>
                            ) : resellers.length === 0 ? (
                                <div className="py-16 text-center bg-gray-50 rounded-2xl border border-dashed border-gray-200">
                                    <UserGroupIcon className="w-12 h-12 text-gray-300 mx-auto mb-4" />
                                    <p className="text-gray-500 font-medium">No resellers managed by this member yet.</p>
                                </div>
                            ) : (
                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                    {resellers.map((reseller: any) => (
                                        <div 
                                            key={reseller.id}
                                            className="p-4 rounded-2xl border border-gray-100 hover:border-indigo-100 hover:bg-indigo-50/30 transition-all group"
                                        >
                                            <div className="flex items-center gap-4">
                                                <div className="w-12 h-12 bg-indigo-100 rounded-xl flex items-center justify-center text-indigo-600 font-black text-lg uppercase shadow-sm">
                                                    {reseller.name.charAt(0)}
                                                </div>
                                                <div className="min-w-0 flex-1">
                                                    <p className="font-bold text-gray-900 truncate">{reseller.name}</p>
                                                    <p className="text-xs text-gray-500 truncate">{reseller.phone}</p>
                                                </div>
                                                <Link 
                                                    to={`/admin/resellers/edit/${reseller.id}`}
                                                    className="p-2 bg-white text-gray-400 hover:text-indigo-600 rounded-lg border border-gray-100 hover:border-indigo-100 shadow-sm transition-all opacity-0 group-hover:opacity-100"
                                                >
                                                    <ArrowRightIcon className="w-4 h-4" />
                                                </Link>
                                            </div>
                                            <div className="mt-4 flex items-center justify-between pt-4 border-t border-gray-50">
                                                <span className={`text-[10px] font-black uppercase tracking-widest px-2 py-0.5 rounded-md ${
                                                    reseller.status === 'ACTIVE' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                                                }`}>
                                                    {reseller.status}
                                                </span>
                                                <span className="text-[10px] text-gray-400 font-medium">
                                                    Code: {reseller.referral_code}
                                                </span>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>
                    )}

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
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-gray-100">
                                        {payouts.length === 0 ? (
                                            <tr>
                                                <td colSpan={3} className="px-6 py-8 text-center text-gray-500">No payouts found.</td>
                                            </tr>
                                        ) : (
                                            payouts.map((p) => (
                                                <tr key={p.id}>
                                                    <td className="px-6 py-4 text-sm text-gray-600">{new Date(p.created_at).toLocaleDateString()}</td>
                                                    <td className="px-6 py-4 text-sm text-blue-600 font-bold">{formatPrice(p.amount)}</td>
                                                    <td className="px-6 py-4">
                                                        <button onClick={() => setSelectedProofUrl(getImageUrl(p.proof_object_key))} className="text-xs font-bold text-indigo-600">View Proof</button>
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
                                                className="w-full pl-12 pr-4 py-4 border-2 border-gray-100 rounded-2xl focus:border-indigo-500 focus:ring-0 text-xl font-bold text-gray-900 transition-all"
                                                placeholder="0"
                                            />
                                        </div>
                                        <p className="mt-2 text-sm text-gray-500 flex justify-between">
                                            <span>Maximum: <b>{formatPrice(stats?.available_balance || 0)}</b></span>
                                        </p>
                                    </div>

                                    <div>
                                        <label className="block text-sm font-bold text-gray-700 mb-2 uppercase tracking-wider">Proof of Transfer (Image)</label>
                                        <div className="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-200 border-dashed rounded-2xl hover:border-indigo-400 transition-all cursor-pointer relative group">
                                            <input
                                                type="file"
                                                accept="image/*"
                                                required
                                                onChange={(e) => setPayoutForm({ ...payoutForm, proof: e.target.files?.[0] || null })}
                                                className="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                                            />
                                            <div className="space-y-1 text-center">
                                                <PhotoIcon className="mx-auto h-12 w-12 text-gray-400 group-hover:text-indigo-500 transition-colors" />
                                                <div className="flex text-sm text-gray-600">
                                                    <span className="relative font-bold text-indigo-600">
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
                                            className="w-full px-4 py-3 border-2 border-gray-100 rounded-2xl focus:border-indigo-500 focus:ring-0 text-gray-700 transition-all"
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
                                            className={`flex-1 py-4 bg-indigo-600 text-white rounded-2xl font-bold shadow-lg shadow-indigo-200 hover:bg-indigo-700 active:scale-95 transition-all flex items-center justify-center gap-2 ${payoutSaving ? 'opacity-50' : ''}`}
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

export default EditMember;
