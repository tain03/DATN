import { cn } from '@/lib/utils'

interface SkeletonProps extends React.ComponentProps<'div'> {
  variant?: 'default' | 'shimmer' | 'pulse'
}

function Skeleton({ className, variant = 'default', ...props }: SkeletonProps) {
  return (
    <div
      data-slot="skeleton"
      className={cn(
        'bg-accent rounded-md',
        variant === 'shimmer' && 'relative overflow-hidden after:absolute after:inset-0 after:animate-shimmer-gradient',
        variant === 'pulse' && 'animate-pulse',
        variant === 'default' && 'animate-pulse',
        className
      )}
      {...props}
    />
  )
}

function SkeletonText({ className, lines = 3, ...props }: React.ComponentProps<'div'> & { lines?: number }) {
  return (
    <div className={cn('space-y-2', className)} {...props}>
      {Array.from({ length: lines }).map((_, i) => (
        <Skeleton
          key={i}
          variant="shimmer"
          className={cn('h-4', i === lines - 1 && 'w-3/4')}
        />
      ))}
    </div>
  )
}

function SkeletonCard({ className, ...props }: React.ComponentProps<'div'>) {
  return (
    <div
      className={cn('rounded-xl border bg-card p-6 shadow-sm space-y-4', className)}
      {...props}
    >
      <div className="flex items-center gap-4">
        <Skeleton variant="shimmer" className="h-12 w-12 rounded-full" />
        <div className="space-y-2 flex-1">
          <Skeleton variant="shimmer" className="h-4 w-1/3" />
          <Skeleton variant="shimmer" className="h-3 w-1/2" />
        </div>
      </div>
      <SkeletonText lines={3} />
    </div>
  )
}

function SkeletonAvatar({ className, size = 'md', ...props }: React.ComponentProps<'div'> & { size?: 'sm' | 'md' | 'lg' }) {
  const sizeClasses = {
    sm: 'h-8 w-8',
    md: 'h-10 w-10',
    lg: 'h-14 w-14',
  }

  return (
    <Skeleton
      variant="shimmer"
      className={cn('rounded-full', sizeClasses[size], className)}
      {...props}
    />
  )
}

export { Skeleton, SkeletonText, SkeletonCard, SkeletonAvatar }
