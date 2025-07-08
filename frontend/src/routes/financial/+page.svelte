<script lang="ts">
	import { onMount } from 'svelte';
	import { homieStore } from '$lib/stores/homieStore';

	let financialData = {
		summary: null as any,
		loading: true
	};

	onMount(async () => {
		homieStore.updateStatus('💰 Financial Manager', 'info');
		homieStore.addLogEntry('💰 Financial Manager module loaded', 'info');
		
		// Load financial summary
		try {
			const response = await fetch('/api/financial/summary');
			const result = await response.json();
			if (result.success) {
				financialData.summary = result.data;
			}
		} catch (error) {
			console.error('Failed to load financial data:', error);
		} finally {
			financialData.loading = false;
		}
	});
</script>

<svelte:head>
	<title>Financial Manager - Homie</title>
	<meta name="description" content="Austrian-focused financial management with tax compliance" />
</svelte:head>

<main class="financial-page">
	<div class="module-header">
		<h1>💰 Financial Manager</h1>
	</div>

	{#if financialData.loading}
		<div class="loading">Loading financial data...</div>
	{:else if financialData.summary}
		<div class="financial-grid">
			<div class="summary-cards">
				<div class="card">
					<h3>Employment Income</h3>
					<div class="amount">€{financialData.summary.total_employment_income?.toLocaleString() || '0'}</div>
				</div>
				<div class="card">
					<h3>Self-Employment</h3>
					<div class="amount">€{financialData.summary.total_self_employment_income?.toLocaleString() || '0'}</div>
				</div>
				<div class="card">
					<h3>Total Expenses</h3>
					<div class="amount">€{financialData.summary.total_expenses?.toLocaleString() || '0'}</div>
				</div>
				<div class="card">
					<h3>Tax Liability</h3>
					<div class="amount">€{financialData.summary.total_tax_liability?.toLocaleString() || '0'}</div>
				</div>
			</div>
			
			<div class="construction-section">
				<h3>🏠 Construction Budget</h3>
				<div class="construction-cards">
					<div class="card">
						<h4>Budget Used</h4>
						<div class="amount">€{financialData.summary.construction_budget_used?.toLocaleString() || '0'}</div>
					</div>
					<div class="card">
						<h4>Remaining</h4>
						<div class="amount">€{financialData.summary.construction_budget_remaining?.toLocaleString() || '0'}</div>
					</div>
				</div>
			</div>
		</div>
	{:else}
		<div class="empty-state">
			<p>🚀 Financial Manager is ready!</p>
			<p>Start by adding income or expenses to see your financial overview.</p>
		</div>
	{/if}
</main>

<style>
	.financial-page {
		padding: 1rem;
		max-width: 1200px;
		margin: 0 auto;
	}

	.module-header {
		text-align: center;
		margin-bottom: 2rem;
	}

	.module-header h1 {
		font-size: 2.5rem;
		margin: 0;
		background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
		background-clip: text;
	}

	.financial-grid {
		display: flex;
		flex-direction: column;
		gap: 2rem;
	}

	.summary-cards {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
		gap: 1rem;
	}

	.construction-cards {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
		gap: 1rem;
	}

	.card {
		background: rgba(255, 255, 255, 0.05);
		border: 1px solid rgba(255, 255, 255, 0.1);
		border-radius: 12px;
		padding: 1.5rem;
		text-align: center;
	}

	.card h3, .card h4 {
		margin: 0 0 1rem 0;
		font-size: 1.1rem;
		color: #cbd5e1;
	}

	.amount {
		font-size: 1.8rem;
		font-weight: 600;
		color: #22c55e;
	}

	.construction-section h3 {
		color: #ffffff;
		margin-bottom: 1rem;
	}

	.loading, .empty-state {
		text-align: center;
		padding: 3rem;
		color: #94a3b8;
	}

	.empty-state p {
		margin: 0.5rem 0;
		font-size: 1.1rem;
	}

	@media (max-width: 768px) {
		.module-header h1 {
			font-size: 2rem;
		}
		
		.summary-cards {
			grid-template-columns: 1fr;
		}
	}
</style> 