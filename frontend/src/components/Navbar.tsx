import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
    MagnifyingGlassIcon,
    ChevronDownIcon,
    UserCircleIcon,
    ArrowRightOnRectangleIcon,
    Squares2X2Icon
} from '@heroicons/react/24/outline';


const Navbar = () => {
    const [search, setSearch] = useState('');
    const [isLoginOpen, setIsLoginOpen] = useState(false);
    const [user, setUser] = useState<{ role: string | null; token: string | null }>({ role: null, token: null });
    const navigate = useNavigate();

    useEffect(() => {
        const token = localStorage.getItem('token');
        const role = localStorage.getItem('role');
        if (token) {
            setUser({ role, token });
        }
    }, []);

    const handleSearch = (e: React.FormEvent) => {
        e.preventDefault();
        navigate(`/?q=${encodeURIComponent(search)}`);
    };

    const handleLogout = () => {
        localStorage.removeItem('token');
        localStorage.removeItem('role');
        setUser({ role: null, token: null });
        navigate('/');
        setIsLoginOpen(false);
    };

    const getRoleLabel = (role: string | null) => {
        if (!role) return 'User';
        if (role === 'SUPER_ADMIN') return 'Super Admin';
        if (role === 'ADMIN') return 'Admin';
        if (role === 'RESELLER') return 'Reseller';
        return role; // Fallback
    };

    const getDashboardLink = () => {
        if (user.role === 'RESELLER') return '/client/dashboard'; // Assuming client/reseller dashboard
        return '/admin/dashboard';
    };

    return (
        <header className="sticky top-0 z-50 bg-[#0B1221] border-b border-gray-800 shadow-lg font-sans text-white">
            <div className="max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8 h-16 sm:h-24 flex items-center justify-between gap-4 sm:gap-8">
                {/* Logo */}
                <Link to="/" className="flex-shrink-0 flex items-center gap-2">
                    <img src="/logo_new.jpg" alt="Gostar Mart" className="h-10 sm:h-20 w-auto object-contain rounded-md shadow-md bg-[#0B1221]" />
                    <span className="text-lg font-black tracking-tighter sm:hidden">GOSTAR</span>
                </Link>

                {/* Search Bar - Desktop */}
                <form onSubmit={handleSearch} className="flex-1 max-w-xl group relative hidden md:block">
                    <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                        <MagnifyingGlassIcon className="h-5 w-5 text-gray-500 group-focus-within:text-rose-500 transition-colors" />
                    </div>
                    <input
                        type="text"
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                        placeholder="Search for cars, gadgets, properties..."
                        className="block w-full pl-11 pr-5 py-3 rounded-full bg-white border-none text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-yellow-500 focus:border-transparent transition-all shadow-md"
                    />
                </form>

                {/* Right Actions */}
                <div className="flex items-center gap-2 sm:gap-4">
                    {/* Action Toggles - Desktop only */}
                    <div className="hidden lg:flex items-center bg-gray-800 rounded-full p-1 border border-gray-700">
                        <span className="px-5 py-2 rounded-full bg-lime-400 text-gray-900 font-bold text-sm shadow-sm cursor-default">Buy</span>
                        <span className="px-5 py-2 rounded-full text-gray-400 font-medium text-sm hover:text-white cursor-pointer transition-colors">Sell</span>
                        <span className="px-5 py-2 rounded-full text-gray-400 font-medium text-sm hover:text-white cursor-pointer transition-colors">Rent</span>
                    </div>

                    <div className="h-8 w-px bg-gray-700 hidden lg:block"></div>

                    <div className="flex items-center gap-2 sm:gap-4">
                        <div className="font-medium text-gray-300 text-xs sm:text-sm hover:text-white cursor-pointer hidden sm:block transition-colors">Contact us</div>

                        {/* Login/User Dropdown */}
                        <div className="relative">
                            <button
                                onClick={() => setIsLoginOpen(!isLoginOpen)}
                                className={`flex items-center gap-1 sm:gap-2 px-3 sm:px-6 py-2 sm:py-2.5 rounded-full font-bold text-xs sm:text-sm hover:shadow-[0_0_15px_rgba(255,255,255,0.3)] transition-all ${user.token
                                    ? 'bg-blue-600 text-white hover:bg-blue-700'
                                    : 'bg-white text-gray-900 hover:bg-gray-100'
                                    }`}
                            >
                                {user.token ? (
                                    <>
                                        <UserCircleIcon className="w-4 h-4 sm:w-5 sm:h-5" />
                                        <span className="hidden xs:inline">{getRoleLabel(user.role)}</span>
                                    </>
                                ) : (
                                    'Login'
                                )}
                                <ChevronDownIcon className={`w-3 h-3 sm:w-4 sm:h-4 transition-transform duration-200 ${isLoginOpen ? 'rotate-180' : ''}`} />
                            </button>

                            {/* Overlay */}
                            {isLoginOpen && (
                                <div className="fixed inset-0 z-40" onClick={() => setIsLoginOpen(false)}></div>
                            )}

                            <div className={`absolute right-0 top-full mt-3 w-48 bg-white rounded-2xl shadow-xl py-2 border border-gray-200 z-50 animate-fade-in-up transition-all duration-200 origin-top-right ${isLoginOpen ? 'opacity-100 scale-100 visible' : 'opacity-0 scale-95 invisible'}`}>
                                {user.token ? (
                                    <>
                                        <div className="px-4 py-2 border-b border-gray-100">
                                            <p className="text-[10px] text-gray-500 font-bold uppercase tracking-wider">Signed in as</p>
                                            <p className="text-sm font-black text-gray-900 truncate">{getRoleLabel(user.role)}</p>
                                        </div>
                                        <button
                                            onClick={() => {
                                                navigate(getDashboardLink());
                                                setIsLoginOpen(false);
                                            }}
                                            className="w-full text-left px-4 py-3 text-sm text-gray-700 hover:bg-gray-50 hover:text-blue-600 font-bold transition-colors flex items-center gap-2"
                                        >
                                            <Squares2X2Icon className="w-4 h-4" />
                                            Dashboard
                                        </button>
                                        <button
                                            onClick={handleLogout}
                                            className="w-full text-left px-4 py-3 text-sm text-red-600 hover:bg-red-50 font-bold transition-colors flex items-center gap-2"
                                        >
                                            <ArrowRightOnRectangleIcon className="w-4 h-4" />
                                            Logout
                                        </button>
                                    </>
                                ) : (
                                    <>
                                        <Link
                                            to="/auth/login/admin"
                                            className="block px-4 py-3 text-sm text-gray-700 hover:bg-gray-50 hover:text-rose-600 font-bold transition-colors"
                                            onClick={() => setIsLoginOpen(false)}
                                        >
                                            Admin Login
                                        </Link>
                                        <Link
                                            to="/auth/login/reseller"
                                            className="block px-4 py-3 text-sm text-gray-700 hover:bg-gray-50 hover:text-rose-600 font-bold transition-colors"
                                            onClick={() => setIsLoginOpen(false)}
                                        >
                                            Reseller Login
                                        </Link>
                                    </>
                                )}
                            </div>
                        </div>

                        {/* Location (Visual) - Desktop only */}
                        <div className="hidden xl:flex items-center gap-2 cursor-pointer hover:bg-white/10 px-3 py-2 rounded-xl transition-colors text-white">
                            <div className="w-8 h-8 rounded-full bg-white/10 flex items-center justify-center text-lg shadow-inner">
                                🇮🇩
                            </div>
                            <div className="text-left">
                                <div className="text-xs font-bold">IDR</div>
                                <div className="text-[10px] text-gray-400 font-medium">Indonesia</div>
                            </div>
                            <ChevronDownIcon className="w-4 h-4 text-gray-500" />
                        </div>
                    </div>
                </div>
            </div>

            {/* Mobile Search - Redesigned */}
            <div className="md:hidden px-4 pb-4 bg-[#0B1221]">
                <form onSubmit={handleSearch} className="relative">
                    <input
                        type="text"
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                        placeholder="Cari mobil, gadget, properti..."
                        className="block w-full pl-10 pr-4 py-2.5 bg-gray-800 text-white border border-gray-700 rounded-xl text-xs focus:ring-2 focus:ring-rose-500 transition-all placeholder-gray-500 outline-none"
                    />
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                        <MagnifyingGlassIcon className="h-4 w-4 text-gray-500" />
                    </div>
                </form>
            </div>
        </header>
    );
};

export default Navbar;
