export default function AdminLoading() {
  return (
    <div className="flex items-center justify-center py-24">
      <div className="flex flex-col items-center gap-4">
        <div className="h-10 w-10 animate-spin rounded-full border-2 border-slate-200 border-t-blue-600" />
        <p className="text-sm text-slate-500">로딩 중...</p>
      </div>
    </div>
  );
}
