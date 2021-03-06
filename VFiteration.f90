subroutine VFiteration()
  use Globals
  use Utils

  implicit none

  integer, parameter :: maxIter = 20000, showError = 500
  real(8), parameter :: tolerance = 1.0d-4
  integer :: iter, ind_a, ind_z, ind_q, ind_g, ind_b

  real(8) :: error_N_vf, error_U_vf, error_W_vf, error_J_vf, error_V_vf, error_N_pf, error_U_pf, error_W_pf, error_vf, error_pf

  real(8), dimension(gp_a,gp_z) :: new_N_vf, new_N_pf, exp_N
  real(8), dimension(gp_a,gp_z,0:1) :: exp_U
  real(8), dimension(gp_a,gp_z,gp_q) :: new_W_vf, new_W_pf, exp_W
  real(8), dimension(gp_a,gp_z,gp_gamma,0:1) :: new_U_vf, new_J_vf, new_U_pf
  real(8), dimension(gp_a,gp_z,gp_q,gp_gamma,0:1) :: new_V_vf

  ! Guess a value for global value functions
  call random_number(N_vf) ! Assign random numbers to N_vf
  call random_number(U_vf)
  call random_number(W_vf)
  call ValueFunctions(N_vf,U_vf,W_vf,J_vf,V_vf)

  ! Initialise new value functions
  new_N_vf = 0.d0
  new_U_vf = 0.d0
  new_W_vf = 0.d0
  new_J_vf = 0.d0
  new_V_vf = 0.d0

  ! Initialise global policy functions
  N_pf = 0.d0
  U_pf = 0.d0
  W_pf = 0.d0

  ! Initialise new policy functions
  new_N_pf = 1.d0
  new_U_pf = 1.d0
  new_W_pf = 1.d0

  ! Value function iteration
  do iter = 1, maxIter
    ! Compute expected values
    call ExpectedValues(exp_N, exp_U, exp_W)

    ! Iterate over all states TODAY
    do ind_a = 1, gp_a
    do ind_z = 1, gp_z
      call value_N(ind_a, exp_N(:,ind_z), new_N_pf(ind_a,ind_z), new_N_vf(ind_a,ind_z))

      do ind_q = 1, gp_q
        call value_W(ind_a, ind_z, ind_q, exp_W(:,ind_z,ind_q), &
                    new_W_pf(ind_a,ind_z,ind_q), new_W_vf(ind_a,ind_z,ind_q))
      end do

      do ind_b = 0,1
        do ind_g = 1, gp_gamma
          call value_U(ind_a, ind_z, ind_g, ind_b, exp_U(:,ind_z,ind_b), &
                      new_U_pf(ind_a,ind_z,ind_g,ind_b), new_U_vf(ind_a,ind_z,ind_g,ind_b))
        end do
      end do
    end do
    end do

    ! Compute new J and new V
    call ValueFunctions(new_N_vf,new_U_vf,new_W_vf,new_J_vf,new_V_vf)

    ! Compute errors
    error_N_vf = maxval(abs(new_N_vf-N_vf))
    error_U_vf = maxval(abs(new_U_vf-U_vf))
    error_W_vf = maxval(abs(new_W_vf-W_vf))
    error_J_vf = maxval(abs(new_J_vf-J_vf))
    error_V_vf = maxval(abs(new_V_vf-V_vf))
    error_vf = max(error_N_vf, error_U_vf, error_W_vf, error_J_vf, error_V_vf)

    error_N_pf = maxval(abs(new_N_pf-N_pf))
    error_U_pf = maxval(abs(new_U_pf-U_pf))
    error_W_pf = maxval(abs(new_W_pf-W_pf))
    error_pf = max(error_N_pf, error_U_pf, error_W_pf)

    ! Update value functions and decision rules
    N_vf = new_N_vf
    U_vf = new_U_vf
    W_vf = new_W_vf
    J_vf = new_J_vf
    V_vf = new_V_vf

    N_pf = new_N_pf
    U_pf = new_U_pf
    W_pf = new_W_pf

    if ((error_vf.lt.tolerance).and.(error_pf.lt.tolerance)) then
      print *, "Value function iteration finished at iteration:", iter
      print *, ""
      exit
    elseif (mod(iter,showError).eq.0) then
      print *, "Current value function iteration errors, at iteration:", iter
      print *, "Error for N is:", error_N_vf
      print *, "Error for U is:", error_U_vf
      print *, "Error for W is:", error_W_vf
      print *, "Error for J is:", error_J_vf
      print *, "Error for V is:", error_V_vf
      print *, "Error for N's policy function is:", error_N_pf
      print *, "Error for U's policy function is:", error_U_pf
      print *, "Error for W's policy function is:", error_W_pf
      print *, ""
    end if
  end do

end subroutine VFiteration

!===== EXPECTED VALUES ============================================================================
subroutine ExpectedValues(exp_N, exp_U, exp_W)
  ! Computes auxiliary vector to store the expected value for each level of assets tomorrow
  use Globals
  implicit none
  integer :: ind_z, ind_q, ind_b, ind_ap, ind_zp, ind_qp, ind_gp, ind_bp
  real(8) :: prob_N, prob_U, prob_W
  real(8), dimension(gp_a,gp_z), intent(out) :: exp_N
  real(8), dimension(gp_a,gp_z,0:1), intent(out) :: exp_U
  real(8), dimension(gp_a,gp_z,gp_q), intent(out) :: exp_W

  ! Initialise arrays to 0
  exp_N = 0.d0
  exp_U = 0.d0
  exp_W = 0.d0

  ! Iterate over values of z TODAY
  do ind_z = 1, gp_z
    ! Iterate over all values of assets, z, q, and gammas tomorrow
    do ind_ap = 1, gp_a
    do ind_zp = 1, gp_z
    do ind_qp = 1, gp_q
    do ind_gp = 1, gp_gamma
      prob_N = z_trans(ind_z,ind_zp)*q_trans(ind_qp)*gamma_trans(ind_gp)
      exp_N(ind_ap,ind_z) = exp_N(ind_ap,ind_z) + prob_N*(&
                      (lambda_n*V_vf(ind_ap,ind_zp,ind_qp,ind_gp,0)) + &
                      ((1.d0-lambda_n)*J_vf(ind_ap,ind_zp,ind_gp,0)))

      ! Iterate over values of match quality TODAY
      prob_W = prob_N
      do ind_q = 1, gp_q
        exp_W(ind_ap,ind_z,ind_q) = exp_W(ind_ap,ind_z,ind_q) + prob_W*(&
                        ((1.d0-sigma-lambda_e)*V_vf(ind_ap,ind_zp,ind_q,ind_gp,0)) + &
                        (lambda_e*V_vf(ind_ap,ind_zp,max(ind_q,ind_qp),ind_gp,0)) + &
                        (sigma*(1.d0-lambda_u)*J_vf(ind_ap,ind_zp,ind_gp,1)) + &
                        (sigma*lambda_u*V_vf(ind_ap,ind_zp,ind_qp,ind_gp,1)))
      end do

      ! Iterate over values of UI TODAY and TOMORROW
      do ind_b = 0, 1
      do ind_bp = 0, 1
        prob_U = prob_W*IB_trans(ind_b,ind_bp)
        exp_U(ind_ap,ind_z,ind_b) = exp_U(ind_ap,ind_z,ind_b) + prob_U*(&
                        (lambda_u*V_vf(ind_ap,ind_zp,ind_qp,ind_gp,ind_bp)) + &
                        ((1.d0-lambda_u)*J_vf(ind_ap,ind_zp,ind_gp,ind_bp)))
      end do
      end do
    end do
    end do
    end do
    end do
  end do
end subroutine ExpectedValues

!===== OLF ========================================================================================
subroutine value_N(ind_a, aux_exp, pf, vf)
  use Globals
  use Utils
  implicit none

  integer, intent(in) :: ind_a
  real(8) :: aux_max_a, income
  real(8), dimension(gp_a), intent(in) :: aux_exp
  real(8), intent(out) :: pf, vf

  ! Compute income
  income = (1.d0+int_rate)*a_values(ind_a) + T

  ! Compute upper bound for assets
  aux_max_a = min(max_a-tiny, max(min_a, income))

  ! Find level of assets that maximised Bellman Equation
  call golden_method(valor_N, min_a, aux_max_a, pf, vf)

CONTAINS
  real(8) function valor_N(ap)
    implicit none
    real(8), intent(in) :: ap
    real(8) :: aux_inter, cons

    ! Compute interpolated value for tomorrow
    aux_inter = my_inter(a_values, aux_exp, gp_a, ap)

    ! Compute consumption
    cons = income - ap

    valor_N = u(cons) + beta*aux_inter
  end function valor_N
end subroutine value_N

!===== EMPLOYED ===================================================================================
subroutine value_W(ind_a, ind_z, ind_q, aux_exp, pf, vf)
  use Globals
  use Utils
  implicit none

  integer, intent(in) :: ind_a, ind_z, ind_q
  real(8) :: aux_max_a, income
  real(8), dimension(gp_a), intent(in) :: aux_exp
  real(8), intent(out) :: pf, vf

  ! Compute income
  income = (1.d0+int_rate)*a_values(ind_a) + T + (1.d0-tau)*wage*z_values(ind_z)*q_values(ind_q)

  ! Compute upper bound for assets
  aux_max_a = min(max_a-tiny, max(min_a, income))

  ! Find level of assets that maximised Bellman Equation
  call golden_method(valor_W, min_a, aux_max_a, pf, vf)

CONTAINS
  real(8) function valor_W(ap)
    implicit none
    real(8), intent(in) :: ap
    real(8) :: aux_inter, cons

    ! Compute interpolated value for tomorrow
    aux_inter = my_inter(a_values, aux_exp, gp_a, ap)

    ! Compute consumption
    cons = income - ap

    valor_W = u(cons) - alpha + beta*aux_inter
  end function valor_W
end subroutine value_W

!===== EMPLOYED ===================================================================================
subroutine value_U(ind_a, ind_z, ind_g, ind_b, aux_exp, pf, vf)
  use Globals
  use Utils
  implicit none

  integer, intent(in) :: ind_a, ind_z, ind_g, ind_b
  real(8) :: aux_max_a, income
  real(8), dimension(gp_a), intent(in) :: aux_exp
  real(8), intent(out) :: pf, vf

  ! Compute income
  income = (1.d0+int_rate)*a_values(ind_a) + T + (1.d0-tau)*real(ind_b)*benefits(z_values(ind_z))

  ! Compute upper bound for assets
  aux_max_a = min(max_a-tiny, max(min_a, income))

  ! Find level of assets that maximised Bellman Equation
  call golden_method(valor_U, min_a, aux_max_a, pf, vf)

CONTAINS
  real(8) function valor_U(ap)
    implicit none
    real(8), intent(in) :: ap
    real(8) :: aux_inter, cons

    ! Compute interpolated value for tomorrow
    aux_inter = my_inter(a_values, aux_exp, gp_a, ap)

    ! Compute consumption
    cons = income - ap

    valor_U = u(cons) - gamma_values(ind_g) + beta*aux_inter
  end function valor_U
end subroutine value_U
